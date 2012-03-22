root = exports ? this

class root.CSMVCModel extends root.CSMVCObservable
	# create a new model from an entity
	@fromEntity: (entity) ->
		model = new @()

		for property, type of entity.constructor.getColumns()
			model[property] = entity[property]
		model

	constructor: (attributes) ->
		super
		@[prop] = attributes[prop] for prop of attributes
		@

	mergeEntity: (entity) ->
		for property, type of entity.constructor.getColumns()
			@[property] = entity[property]
		@
