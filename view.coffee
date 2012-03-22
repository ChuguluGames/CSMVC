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
			updateMethods: {}
			elements     : {}
		@el    = null

		@[property] = attributes[property] for property of attributes
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
		$(@el).remove()
		@

	setDataBinding: (properties) ->
		for property in properties
			if property.substr(0, 2) is 'on' and /[A-Z]/.test(property.substr(2, 1))
				eventType = property.substr(2, property.length).underscore()
				@_watchModelEvent eventType
			else
				@_watchModelProperty property

	update: (property, value) ->
		# TODO: rename property name
		if typeof property is 'object'
			for prop, value of property
				@update prop, value
		else
			element = @getElement('.' + property, @el)
			element.html value

	_execUpdateMethod: (property, value) ->
		alias = 'update_' + property.underscore()
		unless @_cache.updateMethods[alias]?
			methodName = alias.camelize(yes)
			if @[methodName]? then method = @[methodName]
			else
				method = (value) =>
					@update property, value

			@_cache.updateMethods[alias] = method

		@_cache.updateMethods[alias].call @, value

	_watchModelProperty: (property) ->
		@model.watch property, (value) =>
			@_execUpdateMethod property, value

	_watchModelEvent: (event_type) ->
		@model.on event_type.camelize(yes), (data...) =>
			methodName = ('on_' + event_type).camelize(yes)
			method = @[methodName]
			method.apply @, data if method?

	getElement: (selector, context = null, alias = selector) ->
		unless @_cache[alias]?
			@_cache.elements[alias] = $(selector, context or @el)
		else @_cache.elements[alias]