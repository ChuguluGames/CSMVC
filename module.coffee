moduleKeywords = ['extended', 'included']
root = exports ? this

class root.Module
  # -- static --
  @extend: (module) ->
    for key, value of module when key not in moduleKeywords
      @[key] = value

    module.extended?.apply(@)
    this

  @include: (module) ->
    for key, value of module when key not in moduleKeywords
      # Assign properties to the prototype
      @::[key] = value
      console.log key, value

    module.included?.apply(@)
    this
  # -- static --

  extend: (module) ->
    for key, value of module
      @[key] = value
    this

  include: (module) ->
    for key, value of new module
      @[key] = value
    this