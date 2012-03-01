root = exports ? this

# dependencies: persistencejs, inflection

class root.Model extends root.Observable
	@define = (@_columns, associations, indexes) ->
		# got SomethingModel, need something
		name = @name.slice(0, -5).toLowerCase() # @name is from coffeescript autogeneration
		@_entity = persistence.define name, _columns

		@_createIndexes(indexes) if indexes?

		$.extend @, @_entity

		@_defined = false
		@_associationsComputed = []

		@_associationsCount = if associations? then associations.length else 0
		@_associationsDefinedCount = 0

		# add relationships
		if @_associationsCount > 0
			for association in associations
				do (association) =>
					@_processAssociation association

		else
			@_triggerDefinition()

	@_processAssociation = (association) ->
		regex = new RegExp '([a-z_]+) (:[a-zA-Z_]+)'

		matches = association.match regex
		matches.shift()
		associationType = (matches.shift()).camelize(true)
		associationProperty = matches.shift().substr(1)

		if associationType is 'hasMany'
			associationProperty = associationProperty.pluralize()
		else if associationType is 'hasOne' or associationType is 'belongsTo'
			associationProperty = associationProperty.singularize().toString() # got a weird but with return of Object String

		associationModelName = (associationProperty.singularize() + "_model").camelize()

		associationModel = window[associationModelName]

		associationComputed =
			type      : associationType
			property  : associationProperty
			model_name: associationModelName

		@_associationsComputed.push associationComputed

		callback = (model) =>
			associationComputed.model = model
			reverseAssociation = model.getReverseAssociationForModel @name
			@_createAssociation associationComputed, reverseAssociation

		if associationModel? and associationModel.isDefined()
			callback associationModel

		# wait for full model definition
		else $(window).on associationModelName + '_defined', (event, model) => callback model

		if ++@_associationsDefinedCount is @_associationsCount
			@_triggerDefinition()

	@_createAssociation = (association, reverseAssociation) ->
		# une assoc create a new property
		if association.type isnt 'belongsTo'
			if reverseAssociation?
				@[association.type] association.property, association.model, reverseAssociation.property

			else
				# create association without reverse prop
				@[association.type] association.property, association.model, null

	@_triggerDefinition = ->
		@_defined = true
		$(window).trigger @name + "_defined", @

	@_createIndexes = (indexes) ->

		regexColumn = new RegExp 'add_index :([a-z_]+)'
		regexParams = new RegExp ':([a-z_]+) => ([a-z]+)'

		for index in indexes
			split = index.split ','

			matches = split.shift().match regexColumn
			column = matches[1]

			params = {}
			for part in split
				matches = part.match regexParams
				params[matches[1]] = matches[2]

			@_entity.index column, params

	@getReverseAssociationForModel = (modelName) ->
		for association in @_associationsComputed
			# console.log association.property
			if association.model_name is modelName
				return association
		null

	@isDefined = ->
		@_defined
	#
	constructor: (attributes) ->
		@_entity = new @constructor._entity(attributes)
		$.extend @, @_entity

		for association in @constructor._associationsComputed
			@_addGetterAndSetter association.property

	_addGetterAndSetter: (property) ->
	  Object.defineProperty @, property,
	    get: ->
	      @_entity[property]
	    ,
	    set: (value) ->
	    	@_entity[property] = value
	    ,
	    enumerable: true,
	    configurable: true
