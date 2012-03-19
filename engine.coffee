root = exports ? this

class root.CSMVCEngine extends root.CSMVCObservable
	setDelegate: (@_delegate) ->

	delegate: (action, data...) ->
		camelizedAction = action.camelize yes
		@_delegate[camelizedAction].apply(@_delegate, data) if @_delegate? and @_delegate[camelizedAction]?