# description #

CSMVC is a little MVC framework developped in CoffeeScript.

# dependencies #

* inflection ([google code](http://code.google.com/p/inflection-js/]))
* persistence.js ([github](https://github.com/zefhemel/persistencejs]))
* jQuery ([website](http://jquery.com/]))

# CSMVCObservable #

## Available static methods ##
* on (eventType, handler)
* off (eventType, handler)
* trigger (eventType, arguments..)

## Available methods ##
* on (eventType, handler)
* off (eventType, handler)
* trigger (eventType, arguments..)
* watch (property, handler)

```coffeescript
class PlayerObservable extends CSMVCObservable
  x: 0

  constructor: ->
    super

    @on 'change:x', (x) ->
      console.log 'x:' + x

    @on 'stop', ->
      console.log 'stop'
      @off 'change:x'
      @off 'stop'

    @move()

  mode: ->
    timer = setInterval =>
      if ++x is 100
        @trigger 'stop'
        clearInterval timer

    , 100

```

# CSMVCApplication < CSMVCObservable #

## Available methods ##
* require typePluralized, name

```coffeescript
class App extends CSMVCApplication
  modules:
    helpers:
      'database'
      'log'
    models:
      'avatar'
      'player'
      'team'
    routers:
      'main'
    templates:
      'home'
    views:
      'home'
    controllers:
      'home'

  constructor: ->
    super
    @router = new MainRouter()
    @router.startHistory()

```

# CSMVCRouter < Observable #

## Overridable settings ##
* routesMasks: {}
* rules: {}

## Options ##
* reverse: false
* recursive: true

## Available methods ##
* startHistory
* setRoute (route)
* getRoute
* refresh
* dispatch (route)

```coffeescript
class exports.MainRouter extends CSMVCRouter
  rules:
    home: -> @loadPage new HomeController()
    catalogue:
      settings:
        reverse:   true
        recursive: false
      'show/:id': (id) ->
        @loadPage new CatalogueItemController(id)

  loadPage: (controller) ->
    ...
```

# CSMVCEntity < CSMVCObservable #

## Available relationships ##
* has many XXX
* has many XXX as YYY
* has one XXX
* has one XXX as YYY
* belongs to a XXX
* belongs to XXX as YYY
* is a XXX
* XXX is unique
* has an index on XXX
* XXX is a foreign key for YYY in UUU as PPP
* XXX is a foreign key for YYY in {UUU} as PPP

## Available options index ##
* unique

```coffeescript
class exports.PlayerModel extends CSMVCEntity
  define {
    'nickname': 'TEXT'
  }, [
    'has_one team'
    'has_one avatar'
    'nickname is unique'
  ]

class exports.TeamModel extends CSMVCEntity
  define {
    'name': 'TEXT'
  }, [
    'has_many players'
  ]

class exports.AvatarModel extends CSMVCEntity
  define {
    'path': 'TEXT'
  }, [
    'belongs_to a player'
  ]
```

# CSMVCController < CSMVCObservable #

## Overridable settings ##
* events: {}

## Available methods ##
* addEvent (selector, eventName, method)
* delegateEvents (context, action = 'on')
* delegateEvent (selector, context, eventName, handler, action = 'on')
* delegateNewEvent (selector, context, eventName, method, action = 'on')

```coffeescript
class exports.HomeController extends CSMVCController
  events:
    '#play click': 'onClickGame'

  viewClass: HomeView

  constructor: ->
    super
    @view = new @viewClass()
    @view.render().el.appendTo $('body')
    @deleteEvents @view

  onLeave: ->
    @view.destroy()
```

# CSMVCView < CSMVCObservable #

## Overridable settings##
* attributes: {}
* tag: 'div'
* autoMake: true

## Available methods ##
* destroy

```coffeescript

class exports.HomeView extends CSMVCView
  attributes:
    'data-role': 'page'
    style: 'display:none'

  tag: "div"
  template: HomeTemplate

  render: ->
    $(@el).html @template()
    el

```
