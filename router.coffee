root = exports ? this

# TODO: add optional argument possibility for masks: :id?
# TODO: add exactMatch option for route and global settings
# TODO: add addRoute()

class root.CSMVCRouter extends root.CSMVCObservable
	# default route masks
	# see @addRouteMask for adding a mask
	# see @removeRouteMask for adding a mask
	_routesMasks:
		':id'           : '([0-9]+)'
		':numeric'      : '([0-9]+)'
		':alphabet'     : '([a-zA-Z]+)'
		':lower'        : '([a-z]+)'
		':upper'        : '([A-Z]+)'
		':varchar'      : '([a-zA-Z_-]+)'
		':alphanumeric' : '([a-zA-Z0-9_-]+)'

	# rules of routes
	# rules:
	# 	home: -> new HomeController().show()
	# 	error:
	# 		settings:
	# 			reverse         : true # don't need unknown error
	# 			stopAtFirstMatch: true # error/error404 won't pass :numeric mask
	# 		on: ->
	# 			# unknown error
	# 			controller = new ErrorController()
	# 			controller.display()

	# 		':numeric': (code) ->
	# 				controller = new ErrorController()
	# 				controller.setErrorCode code
	# 				controller.display()

	# 		':alphanumeric': (errorType) ->

	# 				controller = new ErrorController()
	# 				controller.setErrorType errorType
	# 				controller.display()

	rules     : {}

	_rulesList: {}

	# global settings (for all routes)
	_settings:
		redirectIfEmpty: true  # if no route, redirect on home
		reverse        : false # global reverse binding routes
		recursive      : true  # stop at first level route

	# local settings: (for a specific route)
	_rulesSettings:
		reverse         : false # local reverse binding routes
		recursive       : true  # stop at current level route
		stopAtFirstMatch: false # stop at first child route match

	# see @_settings, expect an optional object
	constructor: (options) ->
		super

		# override defaults
		@_settings = @mergeObject @_settings, options

		# generate the recursive list of the rules
		@_rulesList = @_generateRulesList @rules

		# first rule is home
		for rule, settings of @rules
			@home = rule
			break

		# reverse the list
		if @_settings.reverse
			@_rulesList = @_rulesList.reverse()

	# add route mask
	addRouteMask: (alias, regexString) ->
		@_routesMasks[':' + alias] = regexString

	# remove route mask
	removeRouteMask: (alias) ->
		if @_routesMasks[':' + alias]?
			delete @_routesMasks[':' + alias]

	startHistory: ->
		currentRoute = @getRoute()

		# empty first route
		if currentRoute is "" and @_settings.redirectIfEmpty
			@setRoute @home
		else @dispatch currentRoute

		@_addListener()

	_generateRulesList: (rules, ruleParentObject = null) ->
		_rulesList = []

		for rule, params of rules
			if rule isnt 'on' and rule isnt '_settings'

				ruleObject =
					rule    : rule
					fullRule: if ruleParentObject? then ruleParentObject.fullRule + "/" + rule else rule
					level   : if ruleParentObject? then ruleParentObject.level + 1 else 0
					parent  : ruleParentObject
					settings: params.settings
					params  : params

				ruleObject.regex = @_getRegex ruleObject.fullRule

				if typeof params is 'function'
					ruleObject.callback = params
					_rulesList.push ruleObject
				else
					if params.on? and typeof params.on is 'function'
						ruleObject.callback = params.on
						_rulesList.push ruleObject

		# reverse the list if the parent wants to
		if ruleParentObject? and ruleParentObject.settings? and ruleParentObject.settings.reverse
			_rulesList.reverse()

		__rulesList = []
		# get the childs of each rule
		for rule in _rulesList
			__rulesList.push rule
			# don't need to get the childs of it's not recursive (keep it otherwise in case of global reverse)
			if not rule.settings? or not rule.settings.recursive? or rule.settings.recursive
				childs = @_generateRulesList rule.params, rule
				# merge the childs into the global list
				__rulesList = __rulesList.concat(childs)

		_rulesList = null # delete reference from memory
		__rulesList

	_getRegex: (rule) ->
		pattern = @_getPatternOfString rule
		regex = new RegExp(pattern)
		regex

	_getPatternOfString: (string) ->
		for mask, maskPattern of @_routesMasks
			regex = new RegExp mask, 'g'
			string = string.replace regex, maskPattern

		string

	_addListener: ->
		$(window).on 'hashchange', =>
			@dispatch @getRoute()

	# replace current hash
	setRoute: (route) ->
		window.location.hash = route

	# return current hash
	getRoute: ->
		window.location.hash.substr(1) # get ride of the first /

	# force binding of current route
	refresh: ->
		currentRoute = @getRoute()
		@dispatch currentRoute

	# go to previous hash
	back: ->
		window.history.back() # use browser history.back method

	# trigger and call each handler for matched routed
	dispatch: (route) ->
		rules = @_findMathedRulesForRoute route
		return unless rules instanceof Array and rules.length > 0
		@trigger "dispatch", route

		if rule = rules[rules.length - 1]
			rule.callback.apply @, rule.matches

	# find matched route for specified route
	_findMathedRulesForRoute: (route) ->
		callbacks = []

		for rule in @_rulesList
			if rule.regex.test(route)

				# just want to match one child?
				if rule.parent? and rule.parent.settings? and rule.parent.settings.stopAtFirstMatch
					# already have one child matched
					if rule.parent.hasOneChildMatched? and rule.parent.hasOneChildMatched
						continue
					else rule.parent.hasOneChildMatched = true

				matches = route.match rule.regex
				matches.shift() # keep just the matches

				callbacks.push
					callback: rule.callback
					matches : matches

				# rule configuration overrides global settings
				if not @_isRecursive (if rule.settings? then rule.settings.recursive else null), @_settings.recursive
					return callbacks

		callbacks

	# return true of a route is recursive or of global recusrsivity is enabled
	_isRecursive: (ruleRecursivity, globalRecursivity) ->
		(ruleRecursivity? and ruleRecursivity) or globalRecursivity