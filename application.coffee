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

		# prepare the modules
		for type, list of @modules
			for module in list
				@require type, module

	# internal require method
	# uses:
	# @require controller, 'game'
	# @require controller, 'game/hud'
	# @require controller, 'game/game.hud'
	require: (typePluralized, modulePath) ->
		# We have to transform the SomethingUIController to SomethingUiController

		# authorize #my_template, for including without any export
		isAClass = yes
		if modulePath.substr(0, 1) is '#'
			modulePath = modulePath.slice(1)
			isAClass = no

		# make sure that the type is singularized
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

		requireClass              = require(modulePath + '/' + moduleFileName)
		# if it's not a class, just require the file
		window[moduleClassName]   = unless isAClass then requireClass else requireClass[moduleClassName]

	# access a required module
	# TODO: if not defined, try to require it
	getModule: (className) ->
		window[className.camelize()]

	# access a new instance of a required module
	# TODO: make sure that we have the module before creating the new instance
	getNewModule: (name) ->
		module = @getModule name
		new module()