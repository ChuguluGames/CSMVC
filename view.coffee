root = exports ? this

class root.CSMVCView extends root.CSMVCObservable
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