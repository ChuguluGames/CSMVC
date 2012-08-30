root = exports ? this

# require jQuery

class root.CSMVCObservable extends CSMVCTools
	# -- static --
	@_observable = null

	# listen a global event
	@on = (eventName, handler) ->
		@_observable ?= new CSMVCObservable()
		@_observable.on eventName, handler

	# remove listener of a global event
	@off = (eventName, handler) ->
		@_observable ?= new CSMVCObservable()
		@_observable.off eventName, handler

	# trigger a global event
	@trigger = (eventName, eventData) ->
		@_observable ?= new CSMVCObservable()
		@_observable.trigger eventName, eventData

	# watch a specific property of an object
	@watch = (property, handler, element = @) ->
		@_observable ?= new CSMVCObservable()
		@_observable.watch property, handler, element

	# watch a specific property of an object
	# call handler after setting the watcher
	@watchAndGet: (property, handler, element = @) ->
		@_observable ?= new CSMVCObservable()
		@_observable.watchAndGet property, handler, element

	# -- static --

	_subscribers      : {} # list of the subscribers of event
	_watchers         : {} # list of the watchers of property
	_definedProperties: [] # list of the defined properties

	constructor: ->
		# reset shared properties(object references)
		@_subscribers       = {}
		@_watchers          = {}
		@_definedProperties = []

	destroy: ->
		@off()
		@_watchers = {}

	# bind one time and kill all previous handlers
	one: (eventType, handler) ->

		internal_handler = (data...) => # add the new one
			handler.apply @, data
			@off(eventType, internal_handler) # kill the handler when triggered
		@on(eventType, internal_handler)

	# listen of an event
	on: (eventType, handler) ->
		eventTypeSplitted = eventType.split(":")
		if eventTypeSplitted.length > 1
			property = eventTypeSplitted[1]
			if not @_watchers[property]?
				@watch(property, @trigger)

		if not this._subscribers[eventType]?
			@_subscribers[eventType] = []

		@_subscribers[eventType].push(handler)
		@

	# remove listener of an event
	# if no specified handler, all subscribers of the event will be erased
	# if no specified eventType, all subscribers of all events will be erased
	off: (eventType, handler) ->
		# remove all
		if not eventType? and not handler?
			@_subscribers = {}
			return

		subscribers = @_subscribers[eventType]
		if subscribers?
			for subscriber, key in subscribers
				if (handler? and subscriber is handler) or not handler?
					subscribers.splice(key, 1)
		@

	# trigger an eventType
	# eventData is optional
	trigger: (eventType, eventData...) ->
		# no subscribers
		return if not @_subscribers[eventType]?

		# tell about the event for each subscriber
		subscribers = @_subscribers[eventType].slice(0)
		for subscriber in subscribers
			subscriber.apply(@, eventData)

	# watch a property
	# handler will be called at each update od the property
	# trigger change:property will be called after handler
	watch: (property, handler, element = @) ->
		@_watchers[property] = true

		@defineProperty element, property, handler

		@on 'change:' + property, handler

	# watch a property and instantly call handler
	watchAndGet: (property, handler, element = @) ->
		@watch.apply @, arguments
		handler.call @, @[property]

	# unWatch a property
	# if no handler specified, all watchers will be erased
	unWatch: (property, handler) ->
		if @_watchers[property]
			@off 'change:' + property, handler

	# create getter/setter on a property
	# add an optional handler when the set method is called
	# trigger change:property at each update of the value
	defineProperty: (element, property, handler = no) ->
		# make sure that we don't define two times the property
		return for definedProperty in @_definedProperties when definedProperty is property
		@_definedProperties.push property
		# Object.defineProperty erase initial value, let's save it
		initialValue = element[property]

		Object.defineProperty element, property,
			get: ->
				element["_" + property] || initialValue
			,
			set: (newValue) ->
				oldValue = element[property]
				element["_" + property] = newValue

				if handler isnt no
					handler.call @, newValue, oldValue

				# trigger the change for the watchers
				@trigger 'change:' + property, newValue, oldValue
			,
			# this property shows up during enumeration of the properties on the corresponding object
			enumerable  : true,
			# the type of this property descriptor may be changed and
			# the property may be deleted from the corresponding object
			configurable: true