root = exports ? this

class root.CSMVCObservable
	@_observable = null
	# start static methods
	@on = (eventName, handler) ->
		observable = @_observable ? new CSMVCObservable()
		observable.on eventName, handler

	@off = (eventName, handler) ->
		observable = @_observable ? new CSMVCObservable()
		observable.off eventName, handler

	@trigger = (eventName, eventData) ->
		observable = @_observable ? new CSMVCObservable()
		observable.trigger eventName, eventData

	@watch = (object, property, handler) ->
		observable = @_observable ? new CSMVCObservable()
		observable.watch property, handler, object
	# end static methods

	_subscribers: {}
	_watchers   : {}

	constructor: ->
		@_subscribers = {}
		@_watchers = {}

	on: (eventType, handler) ->
		eventTypeSplitted = eventType.split(":")
		if eventTypeSplitted.length > 1
			property = eventTypeSplitted[1]
			if not @_watchers[property]?
				@watch(property, @trigger)

		if not this._subscribers[eventType]?
			@_subscribers[eventType] = []

		@_subscribers[eventType].push(handler)

	off: (eventType, handler) ->
		_subscribers = @_subscribers[eventType]
		for key, subscriber in subscribers
			if (handler? and subscriber is handler) or not handler?
				@_subscribers[eventType].splice(key, 1)

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