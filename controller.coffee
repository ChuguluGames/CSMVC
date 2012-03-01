root = exports ? this

class root.Controller extends root.Observable
	_eventSplitter : /^(\S+)\s*(.*)$/
	_handlersEvents: []

	# events:
	# 	'.selector event': 'myHandler'
	# 	'.other_selector': 'myOtherHandler'
	events         : {}

	constructor: (attributes) ->
		super

		@_handlersEvents = []
		@[prop] = attributes[prop] for prop of attributes
		@_createHandlersEvents()

		@

	_createHandlersEvents: ->
		for key, methodName of @events
			do (key, methodName) =>
				method = @[methodName]
				match = key.match(@_eventSplitter)

				@addEvent match[1], match[2], method

	addEvent: (selector, eventName, method) ->
		handlerEvent =
			eventName: eventName
			selector : selector
			handler  : (event) => method.call @, event
		@_handlersEvents.push handlerEvent
		handlerEvent

	delegateEvents: (context, action = 'on') ->
		for event in @_handlersEvents
			@delegateEvent(event.selector, context, event.eventName, event.handler, action)

	delegateNewEvent: (selector, context, eventName, method, action = 'on') ->
		handlerEvent = @addEvent selector, eventName, method
		@delegateEvent selector, context, eventName, handlerEvent.handler, action

	delegateEvent: (selector, context, eventName, handler, action = 'on') ->
		console.log selector + " " + eventName + " " + action

		if not selector?
			$el = $(context)
		else if selector is 'document'
			$el = $(document)
		else if selector is 'window'
			$el = $(window)
		else
			$el = $(selector, context)

		$el[action](eventName, handler)