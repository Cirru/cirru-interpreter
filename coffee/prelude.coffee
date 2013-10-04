
path = require 'path'
fs = require 'fs'
util = require 'util'
EventEmitter = require('events').EventEmitter

{error, parse} = require 'cirru-parser'
main = require './main'

{type, print, stringify, assert} = require './tool'

exports.cirru_error = cirru_error = (token, message) ->
  options =
    text: message
    x: token.x
    y: token.y
    file: token.file
  util.print (error options)
  throw new Error message

cirru_read = (scope, xs) ->
  xs.map (x) ->
    if (type x) is 'object'
      ret = scope[x.text]
      unless ret?
        cirru_error x, "missing: #{x.text}"
      ret
    else if (type x) is 'array'
      main.interpret scope, x
    else
      cirru_error x, "cannot recognize #{stringify x}"

has_no_undefined = (args) ->
  args.map (x) ->
    assert (x isnt undefined), 'undefined not allowed'

longer_than = (args, length) ->
  assert (args.length > length), "args should be longer then #{length}"

length_equal = (args, length) ->
  assert (args.length is length), "length of args should be #{length}"

be_type = (x, a_type) ->
  assert ((type x) is a_type), "#{x} here should be a #{a_type}"

check_numbers = (scope, list) ->
  args = cirru_read scope, list[1..]
  has_no_undefined args
  args.map (x) -> be_type x, 'number'
  args

# prelude

exports.prelude =
  number: (scope, list) ->
    args = list[1..]
    length_equal args, 1
    x = args[0]
    be_type x.text, 'string'
    number = Number x.text
    if isNaN number
      cirru_error x, "#{stringify x.text} is not valid number"
    else
      number

  bool: (scope, list) ->
    args = list[1..]
    length_equal args, 1
    x = args[0]
    if x.text in ['yes', 'true', 'on', 'ok', 'right'] then yes
    else if x.text in ['no', 'false', 'off', 'wrong'] then no
    else if 0 < x < Infinity then yes
    else if -Infinity < x < 0 then no
    else cirru_error x, "#{stringify x.text} is not a valid bool"

  string: (scope, list) ->
    args = list[1..]
    length_equal args, 1
    x = args[0]
    if (type x.text) is 'string' then x.text
    else if (type x) is 'array'
      String (main.interpret scope, x)
    else cirru_error x, "#{x} is not a string"

  array: (scope, list) ->
    args = cirru_read scope, list[1..]
    has_no_undefined args
    args

  hash: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    object = {}
    args.map (pair) ->
      object[pair[0].text] = main.interpret scope, pair[1]
    object

  regex: (scope, list) ->
    args = list[1..]
    length_equal args, 1

    if x? then new RegExp args[0], args[1]
    else new RegExp args[0]

  nil: (scope, list) ->
    null

  at: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    length_equal args, 2


  # operations on scope

  set: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    be_type args[1], 'array'
    the_type = type args[0]
    value = main.interpret scope, args[1]
    key =
      if the_type is 'object'
        args[0].text
      else if the_type is 'array'
        main.interpret scope, args[0]
      else
    scope[key] = value

  get: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    the_type = type args[0]
    if the_type is 'object'
      scope[args[0].text]
    else if the_type is 'array'
      scope[main.interpret scope, args[0]]

  print: (scope, list) ->
    args = list[1..].map (x) ->
      if (type x.text) is 'string' then scope[x]
      else if (type x) is 'array'
        ret = main.interpret scope, x
        # console.log 'should main:::', ret, x
        ret
    has_no_undefined args
    longer_than args, 0
    args = args.map (x) ->
      if x then x else 'nil'
    print args...

  echo: (scope, list) ->
    args = cirru_read scope, list[1..]
    has_no_undefined args
    longer_than args, 0
    print args...

  'get-scope': (scope, list) ->
    scope

  'load-scope': (scope, list) ->
    args = list[1..]
    has_no_undefined args
    longer_than args, 1
    x = args[0]
    if (type x) is 'object'
      child = scope[x.text]
    else if (type x) is 'array'
      child = main.interpret scope, x
    else
      cirru_error args[0], 'should be a link to a scope'
    be_type child, 'object'
    args[1..].map (expression) ->
      assert expression, 'supposed to be expression here'
      main.interpret child, expression

  under: (scope, list) ->
    args = list[1..]
    longer_than args, 2
    has_no_undefined args
    if (type args[0]) is 'object'
      parent = scope[args[0].text]
    else if (type args[0]) is 'array'
      parent = main.interpret scope, args[0]
    else
      cirru_error args[0], 'should be a variable name'
    unless (type args[1]) is 'array'
      cirru_error args[1], 'supposed to be expression here'
    child =
      __proto__: parent
      parent: scope
    unless (type child) is 'object'
      cirru_error args[0], 'not referring to object'
    list[2..].map (expression) ->
      main.interpret child, expression

  code: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    longer_than args, 0
    args.map (expression) -> be_type expression, 'array'

    parent: scope
    ast: args

  eval: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    longer_than args, 0
    args.map (expression) -> be_type expression, 'array'
    code = main.interpret scope, args[0]
    child =
      parent: code.parent
      outer: scope
    ret = no # not sure, but to return something
    code.ast.map (expression) ->
      ret = main.interpret child, expression
    ret

  assert: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    length_equal args, 2
    value = main.interpret scope, args[0]
    note = main.interpret scope, args[1]
    if value is no
      print note
      assert no, "assert #{args[0]} equals #{args[1]} failed"

  comment: (scope, list) ->
    # will return nothing

  equal: (scope, list) ->
    args = cirru_read scope, list[1..]
    has_no_undefined args
    length_equal args, 2
    args[0] is args[1]

  require: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    x = args[0]
    module_path = path.join x.file.path, '../', x.text
    assert (fs.existsSync module_path), "no module named #{module_path}"

    unless ms[module_path]?
      ms[module_path] = {}
      ms[module_path] = main.run scope, (parse module_path)
      watch_scope module_path

    ms[module_path].exports

  add: (scope, list) ->
    args = check_numbers scope, list
    longer_than args, 1
    args.reduce ((x, y) -> x + y), 0

  minus: (scope, list) ->
    args = check_numbers scope, list
    longer_than args, 1
    args.reduce ((x, y) -> x - y), 0

  multiply: (scope, list) ->
    args = check_numbers scope, list
    longer_than args, 1
    args.reduce ((x, y) -> x * y), 0

  divide: (scope, list) ->
    args = check_numbers scope, list
    longer_than args, 1
    args.reduce ((x, y) -> x / y), 0

  round: (scope, list) ->
    args = check_numbers scope, list
    x = args[0]
    Math.round x

  floor: (scope, list) ->
    args = check_numbers scope, list
    x = args[0]
    Math.floor x

ms = {}

reload_scope = ->
  Object.keys(ms).map (module_path) ->
    fs.unwatchFile module_path
  ms = {}

exports.reloading = reloading = new EventEmitter

watch_scope = (module_path) ->
  fs.watchFile module_path, interval: 200, ->
    reload_scope()
    reloading.emit 'reload', module_path