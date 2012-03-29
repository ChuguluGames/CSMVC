root = exports ? this

# require jQuery

class root.CSMVCController extends root.CSMVCObservable
	# events:
	# 	event     : '.selector' event'
	# 	otherEvent: '.other_selector'
	events: {}

	_handlersEvents: []
	# delegate events when view's rendering
	_delegateEventsOnViewRendering: yes

	constructor: (attributes) ->
		super

		# merge attributes in object
		@[prop] = attributes[prop] for prop of attributes

		@_handlersEvents = []
		@_createHandlersEvents()

		# delegate events when the view is rendering
		if @_delegateEventsOnViewRendering
			handlerWatchView = (view) =>
				# view defined
				if view?
					# function to execute when view is rendered
					hanlderOnViewRender = =>
						view.off 'render', hanlderOnViewRender
						@delegateEvents view.el

					view.on 'render', hanlderOnViewRender
					@unWatch 'view', handlerWatchView

			@watch 'view', handlerWatchView
		@

	# create methods and prepare date for each @events
	_createHandlersEvents: ->
		for eventName, selector of @events
			do (eventName, selector) =>
				@addEvent selector, eventName

	# create onEventNameSelector and offEventNameSelector for an event
	# can specify a method on (for custom naming)
	addEvent: (selector, eventName, methodOn) ->
		# remove spaces, #, . -, well all weird character by an underscore
		# ex: replace .my-awesome-selector to my_awesome_selector
		selectorUnderscored = selector.replace /[^a-z0-9]/gi, '_'
		# ex: click_my_awesome_selector
		eventnameAndSelectorUnderscored = eventName.underscore() + '_' + selectorUnderscored
		# ex: off_click_my_awesome_selector
		methodOffName = ('off_' + eventnameAndSelectorUnderscored).camelize(yes)

		# no method on specified
		unless methodOn?
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
		$el[action](eventData.eventName, eventData.handler)

	# undelegate a delegated event
	unDelegateEvent: (eventData) ->
		throw "eventData should be specified"  unless eventData?
		@delegateEvent eventData, 'off'

	# remove all delegated events
	# can remove events from a specific context
	unDelegateEvents: (context) ->
		if context
			@delegateEvents context, 'off'
		else
			for eventData in @_handlersEvents
				@unDelegateEvent eventData

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