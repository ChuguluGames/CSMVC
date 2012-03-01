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
		# accept sub classing: my_class.sub_class
		splittedName        = name.split "."
			# name of file should be my_class_type
		moduleFileName      = splittedName[0] + "_" + typeSingularized
		# file should be in types/
		modulePath          = typePluralized + "/" + moduleFileName
		# class name should be MyClassType
		moduleClass         = (splittedName.join("_") + "_" + typeSingularized).camelize()
		window[moduleClass] = require(modulePath)[moduleClass]