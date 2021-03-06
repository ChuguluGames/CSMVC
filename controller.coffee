root = exports ? this

# require jQuery

class root.CSMVCController extends root.CSMVCObservable
	# events:
	# 	event     : '.selector' event'
	# 	otherEvent: '.other_selector'
	events: null

	_handlersEvents: null
	# delegate events when view's rendering
	_delegateEventsOnViewRendering: yes
	viewClass: null

	constructor: (attributes) ->
		@events = @events || {}
		@_handlersEvents = @_handlersEvents || []

		super

		# merge attributes in object
		@[prop] = attributes[prop] for prop of attributes

		@_createHandlersEvents()

		if @viewClass?
			@view = new @viewClass()

		# delegate events when the view is rendering
		if @_delegateEventsOnViewRendering
			handlerWatchView = (view) =>
				# view defined
				if view?
					# function to execute when view is rendered
					hanlderOnViewRender = =>
						view.off 'show', hanlderOnViewRender
						@delegateEvents view.el

					view.on 'show', hanlderOnViewRender
					@unWatch 'view', handlerWatchView

			@watchAndGet 'view', handlerWatchView
		@

	addLayout: (view, events) ->
		for key, value of events
			@addEvent(key, value)

	# create methods and prepare date for each @events
	_createHandlersEvents: ->
		for selector,eventName of @events
			do (eventName, selector) =>
				@addEvent selector, eventName

	# create onEventNameSelector and offEventNameSelector for an event
	# can specify a method on (for custom naming)
	addEvent: (selector, eventName, methodOn) ->
		@_handlersEvents = @_handlersEvents || []
		# Do not reassigne the same couple selector/event twice
		for handler in @_handlersEvents when handler.selector is selector and handler.eventName is eventName
			return false

		# remove spaces, #, . -, well all weird character by an underscore
		# ex: replace .my-awesome-selector to my_awesome_selector
		selectorUnderscored = selector.replace /[^a-z0-9]/gi, '_'
		# ex: click_my_awesome_selector
		eventnameAndSelectorUnderscored = eventName.underscore() + '_' + selectorUnderscored
		# ex: off_click_my_awesome_selector
		methodOffName = ('off_' + eventnameAndSelectorUnderscored).camelize(yes)

		# no method on specified
		unless methodOn
			# ex: on_click_my_awesome_selector
			methodOnName = ('on_' + eventnameAndSelectorUnderscored).camelize(yes)
			methodOn = @[methodOnName]

		eventData =
			eventName: eventName
			selector : selector
			handler  : (event) => methodOn.call @, event

		# create a method for remove the event if not defined
		unless @[methodOffName]?
			@[methodOffName] = => @unDelegateEvent eventData

		# save the event data to global events array
		@_handlersEvents.push eventData

	# delegate events on a context
	# can undelegate events with action = 'off'
	delegateEvents: (context, action = 'on') ->
		for eventData in @_handlersEvents
			eventData.context = context
			@delegateEvent(eventData, action)

	# delegate an event or undelagate it with action = 'off'
	delegateEvent: (eventData, action = 'on') ->
		$el = @getElement eventData.context, eventData.selector
		$el = @getElement @layout.el, eventData.selector if $el.length is 0 and @layout
		$el[action].call($el, eventData.eventName, eventData.handler)

	# undelegate a delegated event
	unDelegateEvent: (eventData) ->
		throw "eventData should be specified" unless eventData?
		@delegateEvent eventData, 'off'

	# remove all delegated events
	# can remove events from a specific context
	unDelegateEvents: (context) ->
		if context
			@delegateEvents context, 'off'
		else if @_handlersEvents
			for eventData in @_handlersEvents
				@unDelegateEvent eventData

	destroy: (removeView = no) ->
		@unDelegateEvents()
		@view.destroy(removeView) if @view and @view.destroy # destroy without removing html (avoids white screens)
		super

	# get an element
	# @getElement 'window'
	# @getElement context, '.selector'
	# @getElement '.selector'
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