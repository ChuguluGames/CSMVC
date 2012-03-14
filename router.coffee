root = exports ? this

class root.CSMVCRouter extends root.CSMVCObservable
	routesMasks:
		':id'      : '([0-9]+)'
		':alphabet': '([a-zA-Z]+)'
		':lower'   : '([a-z]+)'
		':upper'   : '([A-Z]+)'
		':varchar' : '([a-zA-Z0-9_-]+)'

	rules     : {}
	_rulesList: {}

	_settings:
		redirectIfEmpty: true
		reverse        : false
		recursive      : true

	_rulesSettings:
		reverse         : false
		recursive       : true
		stopAtFirstMatch: false

	constructor: (options) ->
		super

		# override defaults
		@_settings = @_mergeObject @_settings, options

		# generate the recursive list of the rules
		@_rulesList = @_generateRulesList @rules

		# first rule is home
		for rule, settings of @rules
			@home = rule
			break;

		# reverse the list
		if @_settings.reverse
			@_rulesList = @_rulesList.reverse()

	_mergeObject: (defaultObject, overrideObject) ->
		mergedObject = {}

		if defaultObject?
			for key, option of defaultObject
				mergedObject[key] = option

		if overrideObject?
			for key, option of overrideObject
				mergedObject[key] = option

		mergedObject

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

		_rulesList = null
		__rulesList

	_getRegex: (rule) ->
		pattern = @_getPatternOfString rule
		regex = new RegExp(pattern)
		regex

	_getPatternOfString: (string) ->
		for mask, maskPattern of @routesMasks
			regex = new RegExp mask, 'g'
			string = string.replace regex, maskPattern

		string

	_addListener: ->
		$(window).on 'hashchange', =>
			@dispatch @getRoute()

	setRoute: (route) ->
		window.location.hash = route

	getRoute: ->
		window.location.hash.substr(1) # get ride of the first /

	refresh: ->
		currentRoute = @getRoute()
		@dispatch currentRoute

	back: ->
		window.history.back()

	dispatch: (route) ->
		rules = @_findMathedRulesForRoute route

		@trigger "dispatch", route

		for rule in rules
			rule.callback.apply @, rule.matches

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

	_isRecursive: (ruleRecursivity, globalRecursivity) ->
		(ruleRecursivity? and ruleRecursivity) or globalRecursivity