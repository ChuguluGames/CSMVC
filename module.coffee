moduleKeywords = ['extended', 'included']
root = exports ? this

class root.CSMVCModule
  # -- static --
  @extend: (module) ->
    for key, value of module when key not in moduleKeywords
      @[key] = value

    module.extended?.apply(@)
    this

  @include: (module) ->
    throw('include(module) requires module') unless module
    for key, value of module.prototype when key not in ['included', 'extended', 'name']
      @::[key] = value

    included = module.included
    included.apply(this) if included
    @

  # -- static --

  include: (module, createANewInstance = no) ->
    if createANewInstance
      module = new module()
    else module = module.prototype

    throw('include(module) requires module') unless module
    for key, value of module when key not in ['included', 'extended']
      @[key] = value

    # @authorizeAnswering()
    included = module.included
    included.apply(this) if included
    @

  extend: (module) ->
    for key, value of module
      @[key] = value
    this

  # include: (module) ->
  #   for key, value of module
  #     @[key] = value
  #   this