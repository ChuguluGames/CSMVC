root = exports ? this

class root.View extends root.Observable
	attributes: {}
	el        : null
	autoMake  : true
	tag       : "div"

	constructor: (attributes) ->
		super # call observable constructor

		@[property] = attributes[property] for property of attributes
		@make() if @autoMake

	make: ->
		@el = document.createElement(@tag)
		$(@el).attr(@attributes)

	destroy: ->
		$(this.el).remove()