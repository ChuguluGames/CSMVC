root = exports ? this

class root.Observable
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
		return if not @_subscribers[eventType]? # no subscribers

		args = Array.prototype.slice.call(arguments) # convert the arguments list into an array
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
			handler.call(@, "change:" + prop, prop, oldVal, newVal)
		)

		@__defineGetter__(prop, ->
			return @["_" + prop]
		)