# dependencies #

* inflection ([google code](http://code.google.com/p/inflection-js/]))
* persistence.js ([github](https://github.com/zefhemel/persistencejs]))
* jQuery ([website](http://jquery.com/]))

# Observable #

Available methods
* on eventType, handler
* off eventType, handler
* trigger eventType, ..
* watch prop, handler

<code>
class PlayerObservable extends Observable
  x: 0

  constructor: ->
    super

    @on 'change:x', ->
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

</code>

# Application.Observable #

Available methods:
* require typePluralized, name

<code>
class App extends Application
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

</code>

# Router.Observable #

Overridable settings:
* routesMasks: {}
* rules: {}

Options:
* reverse: false
* recursive: true

Available methods:
* startHistory
* setRoute route
* getRoute
* refresh
* dispatch route

<code>
class exports.MainRouter extends Router
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
</code>

# Model.Observable #

Available relationships:
* has_many
* has_one
* belongs_to

Available options index:
* unique

<code>
class exports.PlayerModel extends Model
  define {
    'nickname': 'TEXT'
  }, [
    'has_one :team'
    'has_one :avatar'
  ], [
    'add_index :nickname, :unique => true'
  ]

class exports.TeamModel extends Model
  define {
    'name': 'TEXT'
  }, [
    'has_many :players'
  ]

class exports.AvatarModel extends Model
  define {
    'path': 'TEXT'
  }, [
    'belongs_to :player'
  ]
</code>

# Controller.Observable #

Overridable settings:
* events: {}

Available methods:
* addEvent selector, eventName, method
* delegateEvents context, action = 'on'
* delegateEvent selector, context, eventName, handler, action = 'on'
* delegateNewEvent selector, context, eventName, method, action = 'on'

<code>
class exports.HomeController extends Controller
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
</code>

# View.Observable #

Overridable settings:
* attributes: {}
* tag: 'div'
* autoMake: true

Available methods:
* destroy

<code>

class exports.HomeView extends View
  attributes:
    'data-role': 'page'
    style: 'display:none'

  tag: "div"
  template: HomeTemplate

  render: ->
    $(@el).html @template()
    el

</code>
