root = exports ? this

# dependencies: inflection, jquery

class root.CSMVCView extends root.CSMVCObservable
	attributes: {}    # attributes of view elements
	template  : null  # template method of view element
	autoMake  : true  # create view element on instanciation
	tag       : "div" # tag of the view element
	container : null  # container of the view element

	el        : null # view element

	_cache    : {}

	constructor: (attributes) ->
		super # call observable constructor

		@_cache =
			elements     : {}
			eventMethods : {}
			updateMethods: {}
		@el = null

		@[property] = attributes[property] for property of attributes

		# got a model and some data binding orders?
		if @model? and @modelDataBinding?
			@_initializeModelDataBinding()

		@make() if @autoMake
		@

	# make view element
	make: ->
		@el = document.createElement(@tag)
		$(@el).attr(@attributes)
		@

	# set the container's html with the el's html
	show: ->
		@container.html @el
		@trigger 'show'

	# append view to container
	append: ->
		@container.append @el

	# render view element
	render: (data) ->
		$(@el).html @template(data)
		@append() if @container?
		@trigger 'render'
		@

	# destroy view element
	destroy: ->
		# remove model data binds
		if @modelDataBinding?
			@_removeModelDataBinding()
		@clearCache()              # remove cached elements
		$(@el).remove()            # remove element
		@

	# update an element
	update: (params, value) ->
		if typeof params is 'object'
			for property, value of params
				@update property, value
		else
			element = @getElement('.' + params, @el)
			element.html value

	# remove cached elements
	clearCache: ->
		@_cache = {}

	# prepare model data model binding
	_initializeModelDataBinding: ->
		for property in @modelDataBinding
			# match onSomething
			if property.substr(0, 2) is 'on' and /[A-Z]/.test(property.substr(2, 1))
				eventType = property.substr(2, property.length).underscore()
				@_watchModelEvent eventType
			else
				@_watchModelProperty property

	# remove all data model binding
	_removeModelDataBinding: ->
		for property in @modelDataBinding
			# match onSomething
			if property.substr(0, 2) is 'on' and /[A-Z]/.test(property.substr(2, 1))
				eventType = property.substr(2, property.length).underscore()
				@_unWatchModelEvent eventType
			else
				@_unWatchModelProperty property

	# return @updateElement method
	# if doesn't exist, return @update method
	_getUpdateMethod: (property) ->
		propertyUnderscored = property.underscore()
		alias = 'update_' + propertyUnderscored
		unless @_cache.updateMethods[alias]?
			methodName = alias.camelize(yes)
			# method exists
			if @[methodName]? then method = @[methodName]
			# doesn't exist, let's use instead update
			else
				method = (value) =>
					@update propertyUnderscored, value

			@_cache.updateMethods[alias] = method

		@_cache.updateMethods[alias]

	# execute update element method
	_execUpdateMethod: (property, value) ->
		@_getUpdateMethod(property).call @, value

	# return @onEvent methog
	# if doesn't exist, return undefined
	_getEventMethod: (event_type) ->
		methodNameUnderscored = 'on_' + event_type
		unless @_cache.eventMethods[methodNameUnderscored]?
			@_cache.eventMethods[methodNameUnderscored] = (data...) =>
				methodName = methodNameUnderscored.camelize(yes)
				method = @[methodName]
				method.apply @, data if method?

		@_cache.eventMethods[methodNameUnderscored]

	# execute event method
	_execEventMethod: (event_type, data...) ->
		@_getEventMethod(event_type).apply @, data

	# watch model property
	_watchModelProperty: (property) ->
		@model.watch property, (value) =>
			@_execUpdateMethod property, value

	# unwatch model property
	_unWatchModelProperty: (property, handler) ->
		@model.unWatch property, handler ? @_getUpdateMethod(property)

	# watch model event
	_watchModelEvent: (event_type) ->
		@model.on event_type.camelize(yes), (data...) =>
			@_execEventMethod.apply @, [event_type, data]

	# watch model event
	_unWatchModelEvent: (event_type, handler) ->
		@model.off event_type.camelize(yes), handler ? @_getEventMethod(event_type)

	# get cached element
	# if doesn't exist, return undefined
	getElement: (selector, context = null, alias = selector) ->
		# not cached yet
		unless @_cache[alias]?
			@_cache.elements[alias] = $(selector, context or @el)
		else @_cache.elements[alias]
