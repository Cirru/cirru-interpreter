
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

has_no_undefined = (args, x) ->
  args.map (x) ->
    assert (x isnt undefined), 'undefined not allowed'

longer_than = (args, length) ->
  assert (args.length > length), "args should be longer then #{length}"

length_equal = (args, length) ->
  assert (args.length is length), "length of args should be #{length}"

be_type = (x, a_type) ->
  assert ((type x) is a_type), "#{x} here should be a #{a_type}"

# prelude

exports.prelude =
  number: (scope, list) ->
    args = list[1..]
    length_equal args, 1
    x = args[0]
    be_type x.text, 'string'
    number = parseInt x.text
    if isNaN number
      cirru_error x, "#{stringify x.text} is not valid number"
    else
      number

  bool: (scope, list) ->
    args = list[1..]
    length_equal args, 1
    x = args[0]
    if x.text in ['yes', 'true', 'on', 'ok', 'right'] then yes
    else if x.text in ['no', 'false', 'off', 'wrong'] no
    else cirru_error x, "#{stringify x.text} is not a valid bool"

  string: (scope, list) ->
    args = list[1..]
    length_equal args, 1
    args[0].text

  array: (scope, list) ->
    args = cirru_read scope, list[1..]
    args

  hash: (scope, list) ->
    args = list[1..]
    object = {}
    args.map (pair) ->
      object[pair[0].text] = main.interpret scope, pair[1]
    object

  regex: (scope, list) ->
    args = list[1..]
    length_equal args, 1

    if x? then new RegExp list[1], list[2]
    else new RegExp list[1]

  # operations on scope

  set: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    be_type args[1], 'array'
    the_type = type list[1]
    # print 'the_type', the_type, list[1]
    if the_type is 'object'
      scope[args[0].text] = main.interpret scope, args[1]
    else if the_type is 'array'
      scope[main.interpret scope, list[1]] = main.interpret scope, args[1]

  get: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    the_type = type args[0]
    if the_type is 'object'
      scope[list[1].text]
    else if the_type is 'array'
      scope[main.interpret scope, list[1]]

  print: (scope, list) ->
    args = cirru_read scope, list[1..]
    has_no_undefined args
    longer_than args, 0
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
      cirru_error list[1], 'should be a link to a scope'
    be_type child, 'object'
    args[1..].map (expression) ->
      assert expression, 'supposed to be expression here'
      main.interpret child, expression

  under: (scope, list) ->
    args = list[1..]
    longer_than args, 2
    has_no_undefined args
    if (type list[1]) is 'object'
      parent = scope[list[1].text]
    else if (type list[1]) is 'array'
      parent = main.interpret scope, list[1]
    else
      cirru_error list[1], 'should be a variable name'
    unless (type list[2]) is 'array'
      cirru_error list[2], 'supposed to be expression here'
    child =
      __proto__: parent
      parent: scope
    unless (type child) is 'object'
      cirru_error list[1], 'not referring to object'
    list[2..].map (expression) ->
      main.interpret child, expression

  code: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    longer_than args, 0
    args.map (expression) -> be_type expression, 'array'

    parent: scope
    list: args

  eval: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    longer_than args, 0
    args.map (expression) -> be_type expression, 'array'
    code = main.interpret scope, list[1]
    child =
      parent: code.parent
      outer: scope
    code.list.map (expression) ->
      main.interpret child, expression

  assert: (scope, list) ->
    args = list[1..]
    has_no_undefined args
    length_equal args, 2
    value = main.interpret scope, args[0]
    note = main.interpret scope, args[1]
    if value is no
      print note
      assert no, "assert #{list[1]} equals #{list[2]} failed"

  comment: (scope, list) ->
    # will return nothing

  equal: (scope, list) ->
    args = cirru_read scope, list[1..]
    has_no_undefined args
    length_equal args, 2
    value_1 is value_2

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

    ms[module_path].export

  add: (scope, list) ->
    args = cirru_read scope, list[1..]
    has_no_undefined args
    longer_than args, 1
    args.map (x) -> be_type x, 'number'
    args.reduce ((x, y) -> x + y), 0

ms = {}

reload_scope = ->
  Object.keys(ms).map (module_path) ->
    fs.unwatchFile module_path
  ms = {}

exports.reloading = reloading = new EventEmitter

watch_scope = (module_path) ->
  fs.watchFile module_path, interval: 200, ->
    console.log 'reloading......'
    reload_scope()
    reloading.emit 'reload'
