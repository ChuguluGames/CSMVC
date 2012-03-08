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

class root.Model extends root.Observable
	# -- static --

	@define = (@_columns, @_options = []) ->
		@_name = @name.slice(0, -5).underscore()

		@_isMixin = false
		@_defined = false
		@_associations = []
		@_indexes = []

		@_processOptions()

		@_onReady()

		@_processAssociations()
		@_processIndexes()

	@_onReady = ->

		if @_isMixin
			defineMethod = 'defineMixin'
		else defineMethod = 'define'

		@_entity = persistence[defineMethod] @_name, @_columns

		$.extend @, @_entity # merge entity constructor

	@_processOptions = ->
		return if @_options.length is 0

		regexes = {
			mixin      : new RegExp 'is polymorphic'
			isA        : new RegExp 'is an? ([a-zA-Z_]+)'
			hasMany    : new RegExp 'has many ([a-zA-Z_]+)( as ([a-zA-Z_]+))?'
			hasOne     : new RegExp 'has one ([a-zA-Z_]+)( as ([a-zA-Z_]+))?'
			belongsTo  : new RegExp 'belongs to an? ([a-zA-Z_]+)( as ([a-zA-Z_]+))?'
			index      : new RegExp 'has an index on ([a-zA-Z_]+)'
			uniqueIndex: new RegExp '([a-zA-Z_]+) is unique'
		}

		for option in @_options
			for type, regex of regexes
				if regex.test(option)
					matches = option.match regex
					if matches.length > 0
						matches.shift()
						@["_" + type].apply @, matches

					else
						@["_" + type]()

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
			modelName = @_generateModelName arguments[1]
		else
			property = arguments[1]
			modelName = null

		@_associations.push
			type     : arguments[0]
			property : property
			modelName: modelName

	@_uniqueIndex = (property) ->
		@_index property, {unique: true}

	@_index = (property, params = {}) ->
		@_indexes.push
			property: property
			params  : params

	@_processAssociations = ->
		@_associationsDefinedCount = 0
		for association in @_associations
			@_processAssociation association

	@_processAssociation = (association) ->

		if association.type is 'hasMany'
			association.property = association.property.pluralize()

		else if association.type is 'hasOne' or association.type is 'belongsTo' or association.type is 'is'
			# got a weird bug with return of Object String
			association.property = association.property.singularize().toString()

		if not association.modelName
			association.modelName = @_generateModelName association.property

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

		if ++@_associationsDefinedCount is @_associations.length
			@_triggerDefinition()

	@_createAssociation = (association, reverseAssociation) ->
		# belongs to doesn't require any relationship
		if association.type isnt 'belongsTo'
			if reverseAssociation?
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

	@_processIndexes = ->
		for index in @_indexes
			@_entity.index index.property, index.params

	@_triggerDefinition = ->
		@_defined = true
		$(window).trigger @name + "_defined", @

	@_waitUntilTrigger = (name, callback) ->
		handler = (event, model) =>
			$(window).off name + '_defined', handler
			callback model
		$(window).on name + '_defined', handler

	@_generateModelName = (name) ->
		(name.singularize() + "_model").camelize()

	@isDefined = ->
		@_defined

	@getColumns = ->
		@_columns

	@getAssociations = ->
		@_associations

	# -- static --

	constructor: (attributes) ->
		@_entity = new @constructor._entity(attributes)
		$.extend @, @_entity # merge prototype methods

		# add getter/setter on each columns of the entity
		for property, type in @constructor.getColumns()
			@_addGetterAndSetter property, @_entity

		# add getter/stter on each association of the entity
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
