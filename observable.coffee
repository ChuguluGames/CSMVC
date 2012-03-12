root = exports ? this

class root.Observable
	@_observable = null
	# start static methods
	@on = (eventName, handler) ->
		observable = @_observable ? new Observable()
		observable.on eventName, handler

	@off = (eventName, handler) ->
		observable = @_observable ? new Observable()
		observable.off eventName, handler

	@trigger = (eventName, eventData) ->
		observable = @_observable ? new Observable()
		observable.trigger eventName, eventData
	# end static methods

	_subscribers: {}
	_watchers   : {}

	constructor: ->
		@_subscribers = {}
		@_watchers = {}

	on: (eventType, handler) ->
		prop = eventType.split(":")[1]
		if not @_watchers[prop]?
			@watch(prop, @trigger)

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

	watch: (prop, handler) ->
		oldVal 	= @[prop];

		@_watchers[prop] = true

		@__defineSetter__(prop, (newVal) ->
			@["_" + prop] = newVal
			handler.call(@, "change:" + prop, newVal, oldVal)
		)

		@__defineGetter__(prop, ->
			return @["_" + prop]
		)