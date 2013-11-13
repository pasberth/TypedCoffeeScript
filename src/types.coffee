console = log: ->

pj = try require 'prettyjson'
render = (obj) -> pj?.render obj
CS = require './nodes'
util = require 'util'

# ref: http://coffeescriptcookbook.com/chapters/classes_and_objects/cloning
clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime()) 

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags) 

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance

rewrite = (obj, templates) ->
  return if (typeof obj) in ['string', 'number']
  for key, val of obj
    if (typeof val) is 'string'
      if val in templates
        obj[key] = 'Any' #templates[templates.indexOf(val)] 
    else if val instanceof Object
      rewrite(val, templates)

NumberInterface = ->
  toString:
    name: 'function'
    args: []
    returns: 'String'

ArrayInterface = (T = 'Any') ->
  length: 'Number'
  push:
    name: 'function'
    args: [T]
    returns: 'void'
  unshift:
    name: 'function'
    args: [T]
    returns: 'void'
  shift:
    name: 'function'
    args: []
    returns: T
  toString:
    name: 'function'
    args: []
    returns: 'String'

ObjectInterface = ->
  toString:
    name: 'function'
    args: []
    returns: 'String'
  keys:
    name: 'function'
    args: ['Any']
    returns:
      array: 'String'

class Type
  constructor: ->

# ObjectType :: T -> Object
class ObjectType extends Type
  # :: String -> ()
  constructor:(@type) ->

# ArrayType :: {array :: T} = array: T
class ArrayType extends Type
  constructor:(type) ->
    @array = type

# possibilities :: Type[] = []
class Possibilites extends Array
  constructor: (arr = []) ->
    @push i for i in arr

# Exec down casting
# pass obj :: {x :: Number, name :: String} = {x : 3, y : "hello"}
# ng   obj :: {x :: Number, name :: String} = {x : 3, y : 5 }

# TODO: Add Transparent, Passable, Unknown


# struct Array<T> {
#   array: T
# }

checkAcceptableObject = (left, right) ->
  console.log 'check', left, right

  # possibilites :: Type[]
  if right?.possibilities?
    console.log "--right---", right
    for r in right.possibilities
      checkAcceptableObject left, r
    return

  # {array: "Number"} <> {array: "Number"}
  # {array: "Number"} <> {array: ["Number", 'Number']}
  if left is 'Any' then return

  if left?.array?

    if right.array instanceof Array
      checkAcceptableObject left.array, r for r in right.array
    else
      checkAcceptableObject left.array, right.array

  # "Array" <> array: Number
  else if right?.array?
    if left is 'Array' or left is 'Any' or left is undefined then 'ok'
    else
      throw (new Error "object deep equal mismatch #{JSON.stringify left}, #{JSON.stringify right}")

  else if ((typeof left) is 'string') and ((typeof right) is 'string')
    if (left is right) or (left is 'Any') or (right is 'Any')
      'ok'
    else
      throw (new Error "object deep equal mismatch #{JSON.stringify left}, #{JSON.stringify right}")

  # {x: "Nubmer", y: "Number"} <> {x: "Nubmer", y: "Number"}
  else if ((typeof left) is 'object') and ((typeof right) is 'object')
    for key, lval of left
      # when {x: Number} = {z: Number}
      if right[key] is undefined
        return if key in ['returns', 'type'] # TODO ArrayTypeをこっちで吸収してないから色々きちゃう
        throw new Error "'#{key}' is not defined on right"
      checkAcceptableObject(lval, right[key])
  else if (left is undefined) or (right is undefined)
    # TODO: valid code later
    "ignore now"
  else
    throw (new Error "object deep equal mismatch #{JSON.stringify left}, #{JSON.stringify right}")

# Initialize primitive types
# Number, Boolean, Object, Array, Any
initializeGlobalTypes = (node) ->
  # Primitive
  node.addTypeObject 'String', new TypeSymbol {
    type: 'String'
    instanceof: (expr) -> (typeof expr.data) is 'string'
  }

  node.addTypeObject 'Number', new TypeSymbol {
    type: 'Number'
    instanceof: (expr) -> (typeof expr.data) is 'number'
  }

  node.addTypeObject 'Boolean', new TypeSymbol {
    type: 'Boolean'
    instanceof: (expr) -> (typeof expr.data) is 'boolean'
  }

  node.addTypeObject 'Object', new TypeSymbol {
    type: 'Object'
    instanceof: (expr) -> (typeof expr.data) is 'object'
  }

  node.addTypeObject 'Array', new TypeSymbol {
    type: 'Array'
    instanceof: (expr) -> (typeof expr.data) is 'object'
  }

  node.addTypeObject 'Undefined', new TypeSymbol {
    type: 'Undefined'
    # instanceof: (expr) -> expr.data is 'undefined'
  }

  # Any
  node.addTypeObject 'Any', new TypeSymbol {
    type: 'Any'
    instanceof: (expr) -> true
  }

# Known vars in scope
class VarSymbol
  # type :: String
  # implicit :: Bolean
  constructor: ({@type, @implicit}) ->

# Known types in scope
class TypeSymbol
  # type :: String or Object
  # instanceof :: (Any) -> Boolean
  constructor: ({@type, @instanceof, @templates}) ->
    @instanceof ?= (t) -> t instanceof @constructor

# Var and type scope as node
class Scope
  # constructor :: (Scope) -> Scope

  # Get registered type in my scope
  # addType  :: (String, String) -> ()

  # Get registered type included in parents
  # addTypeInScope  :: (String, String) -> ()

  # for debug
  @dump: (node, prefix = '') ->
    console.log prefix + "[#{node.name}]"
    for key, val of node._vars
      console.log prefix, ' +', key, '::', val
    for next in node.nodes
      Scope.dump next, prefix + '  '

  constructor: (@parent = null) ->
    @parent?.nodes.push this

    @name = ''
    @nodes  = [] #=> scopeeNode...

    # スコープ変数
    @_vars  = {} #=> symbol -> type

    # 登録されている型
    @_types = {} #=> typeName -> type

    # TODO: This Scope
    @_this  = {} #=> null or {}

    # このブロックがReturn する可能性があるもの
    @_returnables = [] #=> [ReturnableType...]

  addReturnable: (symbol, type) ->
    @_returnables.push type

  getReturnables: -> @_returnables

  # addType :: String * Object * Object -> Type
  addType: (symbol, type, templates) ->
    @_types[symbol] = new TypeSymbol {type, templates}

  addTypeObject: (symbol, type_object) ->
    @_types[symbol] = type_object

  getType: (symbol) ->
    @_types[symbol]?.type or undefined

  getTypeInScope: (symbol) ->
    @getType(symbol) or @parent?.getTypeInScope(symbol) or undefined

  addThis: (symbol, type, implicit = true) ->
    @_this[symbol] = {type, implicit}

  getThis: (symbol) ->
    @_this[symbol]?.type ? undefined

  addVar: (symbol, type, implicit = true) ->
    if type?.base?
      # modify type
      T = @getType(type.base)
      return undefined unless T?.type

      obj = clone T.type
      if T.templates then rewrite obj, T.templates
      @_vars[symbol] = new VarSymbol {type:obj, implicit}
    else
      @_vars[symbol] = new VarSymbol {type, implicit}

  getVar: (symbol) ->
    @_vars[symbol]?.type ? undefined

  getVarInScope: (symbol) ->
    @getVar(symbol) or @parent?.getVarInScope(symbol) or undefined

  isImplicitVar: (symbol) -> !! @_vars[symbol]?.implicit

  isImplicitVarInScope: (symbol) ->
    @isImplicitVar(symbol) or @parent?.isImplicitVarInScope(symbol) or undefined

  # Extend symbol to type object
  # ex. {name : String, p : Point} => {name : String, p : { x: Number, y: Number}}
  extendTypeLiteral: (node) ->
    switch (typeof node)
      when 'object'
        # array
        if node instanceof Array
          return (@extendTypeLiteral(i) for i in node)
        # object
        else
          ret = {}
          for key, val of node
            ret[key] = @extendTypeLiteral(val)
          return ret
      when 'string'
        type = @getTypeInScope(node)
        switch typeof type
          when 'object'
            return @extendTypeLiteral(type)
          when 'string'
            return type
            
  # check object literal with extended object
  checkAcceptableObject: (left, right) ->
    l = @extendTypeLiteral(left)
    r = @extendTypeLiteral(right)
    checkAcceptableObject(l, r)

  # Check arguments
  # TODO: integrate to checkAcceptableObject
  checkFunctionLiteral: (left, right) ->
    console.log 'checkFunctionLiteral', left, right 
    # flat extend
    left  = @extendTypeLiteral left
    right = @extendTypeLiteral right
    return if left is undefined or left is 'Any'
    left.args ?= []
    # check args
    console.log left
    if left?.args is undefined
      throw new Error "left is not arguments: #{JSON.stringify left}, #{JSON.stringify right}"
    for l_arg, i in left.args
      r_arg = right.args[i]
      checkAcceptableObject(l_arg, r_arg)

    # check return type
    # TODO: Now I will not infer function return type
    if right.returns isnt 'Any'
      checkAcceptableObject(left.returns, right.returns)

module.exports = {
  checkAcceptableObject, 
  initializeGlobalTypes, 
  VarSymbol, TypeSymbol, Scope, 
  ArrayType, ObjectType, Type, Possibilites
}