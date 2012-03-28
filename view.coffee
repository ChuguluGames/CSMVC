root = exports ? this

# dependencies: inflection, jquery

class root.CSMVCView extends root.CSMVCObservable
	attributes: {}
	template  : null
	el        : null
	autoMake  : true
	tag       : "div"
	container : null
	_cache    : {}

	constructor: (attributes) ->
		super # call observable constructor

		@_cache =
			elements     : {}
			eventMethods : {}
			updateMethods: {}
		@el = null

		@[property] = attributes[property] for property of attributes

		if @model? and @modelDataBinding?
			@_initializeModelDataBinding()

		@make() if @autoMake
		@

	make: ->
		@el = document.createElement(@tag)
		$(@el).attr(@attributes)
		@

	append: ->
		@container.append @el

	render: (data) ->
		$(@el).html @template data
		@trigger 'render'
		@

	destroy: ->
		@clearCache()
		@_removeModelDataBinding()
		$(@el).remove()
		@

	# update an element
	update: (params, value) ->
		if typeof params is 'object'
			for property, value of params
				@update property, value
		else
			element = @getElement('.' + params, @el)
			element.html value

	clearCache: ->
		@_cache = {}

	_initializeModelDataBinding: ->
		for property in @modelDataBinding
			# match onSomething
			if property.substr(0, 2) is 'on' and /[A-Z]/.test(property.substr(2, 1))
				eventType = property.substr(2, property.length).underscore()
				@_watchModelEvent eventType
			else
				@_watchModelProperty property

	_removeModelDataBinding: ->
		for property in @modelDataBinding
			# match onSomething
			if property.substr(0, 2) is 'on' and /[A-Z]/.test(property.substr(2, 1))
				eventType = property.substr(2, property.length).underscore()
				@_unWatchModelEvent eventType
			else
				@_unWatchModelProperty property

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

	_execUpdateMethod: (property, value) ->
		@_getUpdateMethod(property).call @, value

	_getEventMethod: (event_type) ->
		methodNameUnderscored = 'on_' + event_type
		unless @_cache.eventMethods[methodNameUnderscored]?
			@_cache.eventMethods[methodNameUnderscored] = (data...) =>
				methodName = methodNameUnderscored.camelize(yes)
				method = @[methodName]
				method.apply @, data if method?

		@_cache.eventMethods[methodNameUnderscored]

	_execEventMethod: (event_type, data...) ->
		@_getEventMethod(event_type).apply @, data

	_watchModelProperty: (property) ->
		@model.watch property, (value) =>
			@_execUpdateMethod property, value

	_watchModelEvent: (event_type) ->
		@model.on event_type.camelize(yes), (data...) =>
			@_execEventMethod.apply @, [event_type, data]

	_unWatchModelProperty: (property, handler) ->
		@model.unWatch property, handler ? @_getUpdateMethod(property)

	_unWatchModelEvent: (event_type, handler) ->
		@model.off event_type.camelize(yes), handler ? @_getEventMethod(event_type)

	getElement: (selector, context = null, alias = selector) ->
		unless @_cache[alias]?
			@_cache.elements[alias] = $(selector, context or @el)
		else @_cache.elements[alias]
