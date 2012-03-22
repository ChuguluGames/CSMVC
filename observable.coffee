root = exports ? this

class root.CSMVCObservable extends Module
	@_observable = null
	# start static methods
	@on = (eventName, handler) ->
		@_observable ?= new CSMVCObservable()
		@_observable.on eventName, handler

	@off = (eventName, handler) ->
		@_observable ?= new CSMVCObservable()
		@_observable.off eventName, handler

	@trigger = (eventName, eventData) ->
		@_observable ?= new CSMVCObservable()
		@_observable.trigger eventName, eventData

	@watch = (object, property, handler) ->
		@_observable ?= new CSMVCObservable()
		@_observable.watch property, handler, object
	# end static methods

	_subscribers      : {}
	_watchers         : {}
	_definedProperties: []

	constructor: ->
		@_subscribers       = {}
		@_watchers          = {}
		@_definedProperties = []

	# bind one time and kill all previous handlers
	one: (eventType, handler) ->
		@off(eventType) # first kill all previous handlers
			.on(eventType, (data...) => # add the new one
				handler.apply @, data
				@off(eventType) # kill the handler when triggered
			)

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

	off: (eventType, handler) ->
		subscribers = @_subscribers[eventType]
		if subscribers?
			for key, subscriber in subscribers
				if (handler? and subscriber is handler) or not handler?
					subscribers.splice(key, 1)
		@

	trigger: (eventType) ->
		# no subscribers
		return if not @_subscribers[eventType]?

		# convert the arguments list into an array
		args = Array.prototype.slice.call(arguments)
		args.shift() # remove the event type from the array

		# tell about the event for each subscriber
		subscribers = @_subscribers[eventType].slice(0)
		for subscriber in subscribers
			subscriber.apply(@, args)

	watch: (property, handler, element = @) ->
		@_watchers[property] = true

		initialValue = element[property]

		Object.defineProperty element, property,
			get: ->
				element["_" + property] || initialValue # when the property is define, the last property is erased
			,
			set: (newValue) ->
				oldValue = element[property]
				element["_" + property] = newValue

				handler.call(@, newValue, oldValue)
				@trigger 'change:x', newValue, oldValue
			,
			# this property shows up during enumeration of the properties on the corresponding object
			enumerable  : true,
			# the type of this property descriptor may be changed and
			# the property may be deleted from the corresponding object
			configurable: true