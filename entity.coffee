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

# static class with all the entity options regex
class root.EntityRegexes
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

class root.CSMVCEntity extends root.CSMVCObservable
	# -- static --

	@define = (@_columns, @_options = []) ->
		@_class = @name.slice(0, -6)
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

		@_persistenceEntity = persistence[defineMethod] @_name, @_columns

		$.extend @, @_persistenceEntity # merge persistence entity constructor

		@_overrideFindBy()

	@_overrideFindBy = ->
		oldFindBy = @findBy
		@findBy = (property, value, callback) =>
			oldFindBy property, value, (entity) =>
				entity = if entity? then new window[@name](entity) else null
				callback entity

	@_processOptions = ->
		return if @_options.length is 0
		for option in @_options
			# TODO: check if match + result length test faster than reg.test + string.match
			for type, regex of EntityRegexes.regexesOptions
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
		@_persistenceEntity.index(index.property, index.params) for index in @_indexes

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
			foreignKey.targetEntityName = null
			foreignKey.aliasProperty = if arguments[4]? then arguments[4] else null

		else
			foreignKey.targetTable = arguments[3].singularize()
			foreignKey.targetEntityName = @generateEntityName foreignKey.targetTable
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
			entityName = @generateEntityName arguments[1]
		else
			property = arguments[1]
			entityName = null

		@_associations.push
			type     : arguments[0]
			property : property
			entityName: entityName

	@_processAssociations = ->
		for association in @_associations
			@_processAssociation association

	@_processAssociation = (association) ->

		if association.type is 'hasMany'
			association.property = association.property.pluralize()

		else if association.type is 'hasOne' or association.type is 'belongsTo' or association.type is 'is'
			# got a weird bug with return of Object String
			association.property = association.property.singularize().toString()

		if not association.entityName
			association.entityName = @generateEntityName association.property

		association.entity = window[association.entityName]

		callback = (entity) =>
			association.entity = entity
			reverseAssociation = entity.getReverseAssociationForEntity @name
			@_createAssociation association, reverseAssociation

		if association.type is 'is'

			callback = (mixin) =>
				callbackSelfDefinition = (entity) =>
					entity.is mixin

				if @isDefined()
					callbackSelfDefinition @

				# wait until self is ready
				else @_waitUntilTrigger @name, callbackSelfDefinition

		if association.entity? and association.entity.isDefined()
			callback association.entity

		# wait for full entity definition
		else @_waitUntilTrigger association.entityName, callback

	@_createAssociation = (association, reverseAssociation) ->
		# belongs to doesn't require any relationship
		if association.type isnt 'belongsTo'
			if reverseAssociation? and reverseAssociation.property?
				@[association.type](
					association.property,
					association.entity,
					reverseAssociation.property
				)

			else
				# create association without reverse prop
				@[association.type] association.property, association.entity, null

	@getReverseAssociationForEntity = (entityName) ->
		for association in @_associations
			if association.entityName is entityName
				return association
		null

	# end static association methods

	@_triggerDefinition = ->
		@_defined = true
		CSMVCObservable.trigger @name + "_defined", @

	@_waitUntilTrigger = (name, callback) ->
		handler = (entity) =>
			CSMVCObservable.off name + '_defined', handler
			callback entity
		CSMVCObservable.on name + '_defined', handler

	@generateEntityName = (name) ->
		(name.singularize() + "_entity").camelize()

	# start static getters
	@isDefined            = -> @_defined
	@getPersistenceEntity = -> @_persistenceEntity
	@getColumns           = -> @_columns
	@getAssociations      = -> @_associations
	@getForeignKeys       = -> @_foreignKeys
	@getClass             = -> @_class
	# end static getters

	# -- static --

	constructor: (attributes) ->
		constructorEntity = @constructor.getPersistenceEntity()
		# construct from an persistence entity
		if attributes._type? and constructorEntity.meta? and constructorEntity.meta.name? and attributes._type is constructorEntity.meta.name
			@_persistenceEntity = attributes
		else
			@_persistenceEntity = new constructorEntity(attributes)

		$.extend @, @_persistenceEntity # merge persistence entity

		# add getter/setter on each columns of the persistence entity
		for property, type of @constructor.getColumns()
			@defineProperty @_persistenceEntity, property, no, no

		# add getter/setter on each association of the persistence entity
		for association in @constructor.getAssociations()
			@defineProperty @_persistenceEntity, association.property, no, no

	# fetch association
	fetchAssociationWithAllForOne: (association, callback) ->
		@fetchAssociation association, (entity) ->
			if entity?
				entity.fetchAll callback
			else
				callback(@)

	# fetch association as collection
	fetchAssociationWithAllForList: (association, callback) ->
		@fetchAssociation association, (entities) ->
			return callback() if not entities? or entities.length < 1
			countEntities = entities.length
			countCallback = ->
				return callback() if --countEntities <= 0
			for entity in entities
				entity.fetchAll countCallback

	# fetch all entity associations
	fetchAll: (callback) ->
		foreignKeys = @constructor.getForeignKeys()
		return callback(@) if not foreignKeys? or foreignKeys.length < 1
		countForeignKeys = foreignKeys.length
		countCallback = =>
			return callback(@) if --countForeignKeys <= 0
		for foreignKey in foreignKeys
			if foreignKey.aliasProperty is foreignKey.aliasProperty.pluralize()
				@fetchAssociationWithAllForList foreignKey.aliasProperty, countCallback
			else
				@fetchAssociationWithAllForOne foreignKey.aliasProperty, countCallback

	# fetch association for a property of the entity
	# can specify either a callback method or filters on the fetch result
	fetchAssociation: (property, option1, option2) ->
		if typeof option1 is 'function'
			callback = option1
			filters  = null

		# filters specified
		else if typeof option1 is 'object'
			filters  = option1
			callback = option2

		regexReplace = /\{([a-z_]+)\}/gi
		for foreignKey in @constructor.getForeignKeys()
			# need to replace the key
			if foreignKey.targetTable.substr(0, 1) is '{'
				# replace the key with the value of the persistence entity
				targetTable = foreignKey.targetTable.replace regexReplace, (match) =>
					key = match.substr 1, match.length - 2
					@[key].underscore() # need to underscore => EntityClass = entity_class

				foreignKey.targetEntityName = @constructor.generateEntityName targetTable
				foreignKey.aliasProperty ?= targetTable

			# the foreign key is the one we're looking for
			if foreignKey.aliasProperty is property

				targetEntityClass = window[foreignKey.targetEntityName]
				query = targetEntityClass.all()
				# get the entities that match the value
				query = query.filter(foreignKey.targetProperty, '=', @[foreignKey.property])
				if filters?
					query = query.filter.apply(query, filter) for filter in filters

				# if polymorphic
				if foreignKey.targetTypeField?
					# get the entities that match the local entity class
					query = query.filter(foreignKey.targetTypeField, '=', @constructor.getClass())

				# request a collection
				if foreignKey.aliasProperty is foreignKey.aliasProperty.pluralize()
					collection = []
					query.list (entities) =>
						if entities?
							for persistenceEntity in entities
								collection.push new targetEntityClass(persistenceEntity)

						@[foreignKey.aliasProperty] = collection # set the collection
						callback.call @, collection

				# request a simple persistence entity
				else
					query.one (persistenceEntity) =>
						targetEntity = if persistenceEntity? then new targetEntityClass(persistenceEntity) else null
						@[foreignKey.aliasProperty] = targetEntity

						callback.call @, targetEntity

				return

		# fallback on fetch persistence method
		@fetch property, callback
