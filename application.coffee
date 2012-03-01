root = exports ? this

# dependencies: inflection

class root.Application extends root.Observable
# modules:
# 	models:
# 		'my_model'
# 	helpers:
# 		'my_helper'
# 	engines:
# 		'my_class.my_sub_class'

	modules: {}

	constructor: ->
		super

		for type, list of @modules
			for module in list
				@require type, module

	require: (typePluralized, name) ->
		typeSingularized    = typePluralized.singularize()
		splittedName        = name.split "."                           # accept sub classing: my_class.sub_class
		moduleFileName      = splittedName[0] + "_" + typeSingularized # name of file should be my_class_type
		modulePath          = typePluralized + "/" + moduleFileName    # file should be in types/
		moduleClass         = (splittedName.join("_") + "_" + typeSingularized).camelize() # class name should be MyClassType
		window[moduleClass] = require(modulePath)[moduleClass]