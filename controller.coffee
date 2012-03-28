root = exports ? this

class root.CSMVCController extends root.CSMVCObservable
	_eventSplitter : /^(\S+)\s*(.*)$/
	_handlersEvents: []

	# events:
	# 	event: '.selector' event'
	# 	event: '.other_selector'
	# will create @onEventSelector and @onEventOtherSelector
	events: {}
	delegateEventOnViewRendering: yes

	constructor: (attributes) ->
		super

		@_handlersEvents = []
		@[prop] = attributes[prop] for prop of attributes
		@_createHandlersEvents()

		if @delegateEventOnViewRendering
			handlerWatchView = (view) =>
				# view defined
				if view?

					hanlderOnViewRender = =>
						view.off 'render', hanlderOnViewRender
						@delegateEvents view.el

					view.on 'render', hanlderOnViewRender
					@unWatch 'view', handlerWatchView

			@watch 'view', handlerWatchView
		@

	_createHandlersEvents: ->
		for eventName, selector of @events
			do (eventName, selector) =>
				@addEvent selector, eventName

	addEvent: (selector, eventName, method) ->
		# remove spaces, #, . -, well all weird character by an underscore
		selectorUnderscored = selector.replace /[^a-z0-9]/gi, '_'
		eventnameAndSelectorUnderscored = eventName.underscore() + '_' + selectorUnderscored

		methodOffName = ('off_' + eventnameAndSelectorUnderscored).camelize(yes)

		unless method?
			methodOnName = ('on_' + eventnameAndSelectorUnderscored).camelize(yes)
			method = @[methodOnName]

		eventData =
			eventName: eventName
			selector : selector
			handler  : (event) => method.call @, event

		# create a method for remove the event
		@[methodOffName] = => @removeEvent eventData

		@_handlersEvents.push eventData

	delegateEvents: (context, action = 'on') ->
		for eventData in @_handlersEvents
			eventData.context = context
			@delegateEvent(eventData, action)

	delegateEvent: (eventData, action = 'on') ->
		$el = @getElement eventData.context, eventData.selector
		$el[action](eventData.eventName, eventData.handler)

	getElement: (context, selector) ->
		unless selector?
			$el = $(context)
		else if selector is 'document'
			$el = $(document)
		else if selector is 'window'
			$el = $(window)
		else
			$el = $(selector, context)
		$el

	removeEvents: (context) ->
		if context
			@delegateEvents context, 'off'
		else
			for eventData in @_handlersEvents
				@removeEvent eventData

	removeEvent: (eventData) ->
		@delegateEvent eventData, 'off'
