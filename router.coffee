root = exports ? this

class root.Router extends root.Observable
	routesMasks:
		':id'      : '([0-9]+)'
		':alphabet': '([a-zA-Z]+)'

	rules     : {}
	_rulesList: {}

	_settings:
		redirectIfEmpty: true
		reverse        : false
		recursive      : true

	_rulesSettings:
		reverse  : false
		recursive: true

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

	_generateRulesList: (rules, baseRule = "") ->
		_rulesList = []

		for rule, params of rules
			if rule isnt 'on' and rule isnt '_settings'
				baseRule = if baseRule isnt "" then baseRule + "/" + rule else rule
				regex = @_getRegex baseRule

				ruleSettings = params._settings

				if typeof params is 'function'
					_rulesList.push
						settings: ruleSettings
						regex   : regex
						callback: params
				else
					if params.on? and typeof params.on is 'function'
						_rulesList.push
							settings: ruleSettings
							regex   : regex
							callback: params.on

					# don't need to get the childs of it's not recursive (keep it otherwise in case of global reverse)
					if not ruleSettings? or not ruleSettings.recursive? or ruleSettings.recursive
						childs = @_generateRulesList params, baseRule

						# reverse the childs
						if ruleSettings? and ruleSettings.reverse
							childs = childs.reverse()

						_rulesList = _rulesList.concat(childs)

		_rulesList

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

	dispatch: (route) ->
		rules = @_findMathedRulesForRoute route

		@trigger "dispatch", route

		for rule in rules
			rule.callback.apply @, rule.matches

	_findMathedRulesForRoute: (route) ->
		callbacks = []
		for rule in @_rulesList
			console.log rule.regex
			if rule.regex.test(route)

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