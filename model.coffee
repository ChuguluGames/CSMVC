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

	# merge the properties of an CSMVCEntity into the object
	mergeEntity: (entity) ->
		# TODO: use the same method of @fromEntity
		for property, type of entity.constructor.getColumns()
			@[property] = entity[property]
		@
