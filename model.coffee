root = exports ? this

# dependencies: persistencejs, inflection

# has many XXX
# has many XXX as YYY
# has one XXX
# has one XXX as YYY
# belongs to a XXX
# belongs to XXX as YYY
# is a XXX
# XXX is unique
# has an index on XXX
# XXX is a foreign key for YYY in UUU as PPP
# XXX is a foreign key for YYY in {UUU} as PPP

class root.ModelRegexes
	stringPattern = '[a-z_]+'
	stringPatternSurrended = '(' + stringPattern + ')'
	aliasRegex = '(?: as ' + stringPatternSurrended + ')?'
	@regexesOptions =
		mixin      : new RegExp '^is polymorphic$'
		isA        : new RegExp '^is an? ' + stringPatternSurrended + '$', 'i'
		hasMany    : new RegExp '^has many ' + stringPatternSurrended + '' + aliasRegex + '$', 'i'
		hasOne     : new RegExp '^has one ' + stringPatternSurrended + '' + aliasRegex + '$', 'i'
		belongsTo  : new RegExp '^belongs to an? ' + stringPatternSurrended + '' + aliasRegex + '$', 'i'
		index      : new RegExp '^has an index on ' + stringPatternSurrended + '$', 'i'
		uniqueIndex: new RegExp '^' + stringPatternSurrended + ' is unique$', 'i'
		foreignKey : new RegExp '^' + stringPatternSurrended + ' is a foreign key for ' + stringPatternSurrended + '(?: with ' + stringPatternSurrended + ')? in (\{?' + stringPattern + '\}?)' + aliasRegex + '$', 'i'

class root.Model extends root.Observable
	# -- static --

	@define = (@_columns, @_options = []) ->
		@_class = @name.slice(0, -5)
		@_name  = @_class.underscore()

		@_isMixin      = false
		@_defined      = false
		@_associations = []
		@_indexes      = []
		@_foreignKeys  = []

		@_processOptions()
		@_onReady()

		@_processAssociations()
		@_processIndexes()

		@_triggerDefinition()

	@_onReady = ->

		defineMethod = if @_isMixin then 'defineMixin' else 'define'

		@_entity = persistence[defineMethod] @_name, @_columns

		$.extend @, @_entity # merge entity constructor

		@_overrideFindBy()

	@_overrideFindBy = ->
		oldFindBy = @findBy
		@findBy = (property, value, callback) =>
			oldFindBy property, value, (entity) =>
				model = if entity? then new window[@name](entity) else null
				callback(model)

	@_processOptions = ->
		return if @_options.length is 0
		for option in @_options
			# TODO: check if match + result length test faster than reg.test + string.match
			for type, regex of ModelRegexes.regexesOptions
				if regex.test(option)
					matches = option.match regex
					if matches.length > 0
						matches.shift()
						@["_" + type].apply @, matches
					else
						@["_" + type]()
					break

	# start static index methods

	@_uniqueIndex = (property) ->
		@_index property, {unique: true}

	@_index = (property, params = {}) ->
		@_indexes.push
			property: property
			params  : params

	@_processIndexes = ->
		@_entity.index(index.property, index.params) for index in @_indexes

	# end static index methods

	# start static foreign key methods

	@_foreignKey = ->
		foreignKey =
			property       : arguments[0]
			targetProperty : arguments[1]
			targetTypeField: arguments[2]

		# dynamic table name
		if arguments[3]? and arguments[3].substr(0, 1) is '{'
			foreignKey.targetTable = arguments[3]
			foreignKey.targetModelName = null
			foreignKey.aliasProperty = if arguments[4]? then arguments[4] else null

		else
			foreignKey.targetTable = arguments[3].singularize()
			foreignKey.targetModelName = @generateModelName foreignKey.targetTable
			foreignKey.aliasProperty = if arguments[4]? then arguments[4] else foreignKey.targetTable

		@_foreignKeys.push foreignKey

	# end static foreign key methods

	# start static association methods

	@_mixin = ->
		@_isMixin = true

	@_isA = (property) ->
		args = Array.prototype.slice.call arguments
		args.unshift 'is'
		@_addAssociation.apply @, args

	@_hasMany = ->
		args = Array.prototype.slice.call arguments
		args.unshift 'hasMany'
		@_addAssociation.apply @, args

	@_hasOne = ->
		args = Array.prototype.slice.call arguments
		args.unshift 'hasOne'
		@_addAssociation.apply @, args

	@_belongsTo = (property) ->
		args = Array.prototype.slice.call arguments
		args.unshift 'belongsTo'
		@_addAssociation.apply @, args

	@_addAssociation = ->
		if arguments.length is 4 and arguments[3]? and arguments[1]?
			property = arguments[3]
			modelName = @generateModelName arguments[1]
		else
			property = arguments[1]
			modelName = null

		@_associations.push
			type     : arguments[0]
			property : property
			modelName: modelName

	@_processAssociations = ->
		for association in @_associations
			@_processAssociation association

	@_processAssociation = (association) ->

		if association.type is 'hasMany'
			association.property = association.property.pluralize()

		else if association.type is 'hasOne' or association.type is 'belongsTo' or association.type is 'is'
			# got a weird bug with return of Object String
			association.property = association.property.singularize().toString()

		if not association.modelName
			association.modelName = @generateModelName association.property

		association.model = window[association.modelName]

		callback = (model) =>
			association.model = model
			reverseAssociation = model.getReverseAssociationForModel @name
			@_createAssociation association, reverseAssociation

		if association.type is 'is'

			callback = (mixin) =>
				callbackSelfDefinition = (model) =>
					model.is mixin

				if @isDefined()
					callbackSelfDefinition @

				# wait until self is ready
				else @_waitUntilTrigger @name, callbackSelfDefinition

		if association.model? and association.model.isDefined()
			callback association.model

		# wait for full model definition
		else @_waitUntilTrigger association.modelName, callback

	@_createAssociation = (association, reverseAssociation) ->
		# belongs to doesn't require any relationship
		if association.type isnt 'belongsTo'
			if reverseAssociation? and reverseAssociation.property?
				@[association.type](
					association.property,
					association.model,
					reverseAssociation.property
				)

			else
				# create association without reverse prop
				@[association.type] association.property, association.model, null

	@getReverseAssociationForModel = (modelName) ->
		for association in @_associations
			if association.modelName is modelName
				return association
		null

	# end static association methods

	@_triggerDefinition = ->
		@_defined = true
		Observable.trigger @name + "_defined", @

	@_waitUntilTrigger = (name, callback) ->
		handler = (event, model) =>
			Observable.off name + '_defined', handler
			callback model
		Observable.on name + '_defined', handler

	@generateModelName = (name) ->
		(name.singularize() + "_model").camelize()

	# start static getters
	@isDefined       = -> @_defined
	@getEntity       = -> @_entity
	@getColumns      = -> @_columns
	@getAssociations = -> @_associations
	@getForeignKeys  = -> @_foreignKeys
	@getClass        = -> @_class
	# end static getters

	# -- static --

	constructor: (attributes) ->
		constructorEntity = @constructor.getEntity()
		# construct from an entity
		if attributes._type? and constructorEntity.meta? and constructorEntity.meta.name? and attributes._type is constructorEntity.meta.name
			@_entity = attributes
		else
			@_entity = new constructorEntity(attributes)

		$.extend @, @_entity # merge entity

		# add getter/setter on each columns of the entity
		for property, type of @constructor.getColumns()
			@_addGetterAndSetter property, @_entity

		# add getter/setter on each association of the entity
		for association in @constructor.getAssociations()
			@_addGetterAndSetter association.property, @_entity

	_addGetterAndSetter: (property, element) ->
		Object.defineProperty @, property,
			get: ->
				element[property]
			,
			set: (value) ->
				element[property] = value
			,
			enumerable: true,
			configurable: true

	fetchAssociation: (property, callback) ->
		regexReplace = /\{([a-z_]+)\}/gi

		for foreignKey in @constructor.getForeignKeys()

			# need to replace the key
			if foreignKey.targetTable.substr(0, 1) is '{'
				# replace the key with the value of the entity
				targetTable = foreignKey.targetTable.replace regexReplace, (match) =>
					key = match.substr 1, match.length - 2
					@[key].underscore() # need to underscore => ModelClass = model_class

				foreignKey.targetModelName = @constructor.generateModelName targetTable
				foreignKey.aliasProperty ?= targetTable

			# the foreign key is the on we're looking for
			if foreignKey.aliasProperty is property

				targetModelClass = window[foreignKey.targetModelName]
				query = targetModelClass.all()
				# get the entities that match the value
				query = query.filter(foreignKey.targetProperty, '=', @[foreignKey.property])

				# if polymorphic
				if foreignKey.targetTypeField?
					# get the entities that match the local model class
					query = query.filter(foreignKey.targetTypeField, '=', @constructor.getClass())

				# request a collection
				if foreignKey.aliasProperty is foreignKey.aliasProperty.pluralize()
					collection = []
					query.list (entities) =>
						if entities?
							for entity in entities
								collection.push new targetModelClass(entity)

						@[foreignKey.aliasProperty] = collection # set the collection
						callback collection

				# request a simple entity
				else
					query.one (entity) =>
						targetModel = if entity? then new targetModelClass(entity) else null
						@[foreignKey.aliasProperty] = targetModel

						callback targetModel

				return

		# fallback on fetch persistence method
		@fetch property, callback
