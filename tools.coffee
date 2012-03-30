root = exports ? this

# base of the CSMVC classes

_excludedWords = ['name']

class root.CSMVCTools
  # -- static --

  # add module prototypes methods and properties in object prototype
  @include: (module) ->
    for key, value of module.prototype when key not in _excludedWords
      @::[key] = value
    @

  # -- static --

  # add module prototypes methods and properties in object
  include: (module) ->
    for key, value of module.prototype when key not in _excludedWords
      @[key] = value
    @

  # mere two objects into a new one
  mergeObject: (defaultObject, overrideObject) ->
    mergedObject = {}

    if defaultObject?
      for key, option of defaultObject
        mergedObject[key] = option

    if overrideObject?
      for key, option of overrideObject
        mergedObject[key] = option

    mergedObject