root = exports ? this

# dependencies: inflection

class root.CSMVCApplication extends root.CSMVCObservable
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

	require: (typePluralized, modulePath) ->
		# We have to transform the SomethingUIController to SomethingUiController

		typeSingularized          = typePluralized.singularize()
		modulePathSplitted        = modulePath.split('/')
		# take the last part of the sub path
		name                      = modulePathSplitted.pop()
		# accept sub classing: my_class.sub_class
		splittedName              = name.split '.'
		# name of file should be my_class_type
		moduleFileName            = splittedName.shift() + '_' + typeSingularized
		# file should be in types/
		modulePathSplitted.unshift(typePluralized)
		modulePath                = modulePathSplitted.join('/')
		# class name should be MyClassType
		moduleName                = if splittedName.length > 0 then splittedName.pop() + '_' + typeSingularized else moduleFileName
		moduleClassName           = (moduleName).camelize()
		window[moduleClassName]   = require(modulePath + '/' + moduleFileName)[moduleClassName]

	getModule: (name) ->
		window[name.camelize()]