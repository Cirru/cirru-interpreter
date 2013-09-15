
path = require 'path'
fs = require 'fs'
{error, parse} = require 'cirru-parser'
main = require './main'

{type, print, stringify} = require './tool'

exports.log_error = log_error = (token, message) ->
  options =
    text: message
    x: token.x
    y: token.y
    file: token.file
  print (error options)
  throw new Error 'out from log error'

exports.prelude =
  number: (scope, list) ->
    # print 'number:', list
    unless list[1]?
      log_error list[0], 'need number here'
    x = list[1]
    number = parseInt x.text
    if isNaN number
      log_error x, "#{stringify x.text} is not valid number"
    else
      number
  bool: (scope, list) ->
    unless list[1]?
      log_error list[0], 'need bool symbol here'
    x = list[1]
    if x.text in ['yes', 'true', 'on', 'ok', 'right']
      yes
    else if x.text in ['no', 'false', 'off', 'wrong']
      no
    else
      log_error x, "#{stringify x.text} is not a valid bool"
  string: (scope, list) ->
    unless list[1]?
      log_error list[0], 'need string here'
    x = list[1]
    list[1].text
  array: (scope, list) ->
    list[1..].map (x) ->
      the_type = type x
      if the_type is 'object' then x
      else if the_type is 'array'
        main.interpret scope, x
      else log_error x, "#{stringify x.text} is not a valid list item"
  hash: (scope, list) ->
    object = {}
    list[1..].map (pair) ->
      object[pair[0].text] = main.interpret scope, pair[1]
    object
  regex: (scope, list) ->
    unless list[1]?
      log_error list[0], 'need regular expression'
    if list[2]? then new RegExp list[1], list[2]
    else new RegExp list[1]
  # operations on scope
  set: (scope, list) ->
    unless list[1]? and list[2]?
      log_error list[0], 'set need 2 arguments'
    unless (type list[2]) is 'array'
      log_error list[2], 'this should be an expression'
    the_type = type list[1]
    # print 'the_type', the_type, list[1]
    if the_type is 'object'
      scope[list[1].text] = main.interpret scope, list[2]
    else if the_type is 'array'
      scope[main.interpret scope, list[1]] = main.interpret scope, list[2]
  get: (scope, list) ->
    unless list[1]?
      log_error list[0], 'add your variable to get'
    the_type = type list[1]
    if the_type is 'object'
      scope[list[1].text]
    else if the_type is 'array'
      scope[main.interpret scope, list[1]]
  print: (scope, list) ->
    unless list[1]?
      log_error list[0], 'write something you want to print'
    the_type = type list[1]
    if the_type is 'object'
      print list[1].text
    else if the_type is 'array'
      print main.interpret scope, list[1]
  'get-scope': (scope, list) -> scope
  'load-scope': (scope, list) ->
    unless list[1]? and list[2]?
      log_error list[0], 'need at less 2 arguments..'
    if (type list[1]) is 'object'
      child = scope[list[1].text]
    else if (type list[1]) is 'array'
      child = main.interpret scope, list[1]
    else
      log_error list[1], 'should be a variable name'
    unless (type list[2]) is 'array'
      log_error list[2], 'supposed to be expression here'
    unless (type child) is 'object'
      log_error list[1], 'not referring to object'
    list[2..].map (expression) ->
      main.interpret child, expression
  under: (scope, list) ->
    unless list[1]? and list[2]?
      log_error list[0], 'need at less 2 arguments..'
    if (type list[1]) is 'object'
      parent = scope[list[1].text]
    else if (type list[1]) is 'array'
      parent = main.interpret scope, list[1]
    else
      log_error list[1], 'should be a variable name'
    unless (type list[2]) is 'array'
      log_error list[2], 'supposed to be expression here'
    child =
      __proto__: parent
      parent: scope
    unless (type child) is 'object'
      log_error list[1], 'not referring to object'
    list[2..].map (expression) ->
      main.interpret child, expression
  code: (scope, list) ->
    unless list[1]?
      log_error list[0], 'add some code here'
    list[1..].map (expression) ->
      unless (type expression) is 'array'
        log_error list[1], 'use expression'
    parent: scope
    list: list[1..]
  eval: (scope, list) ->
    unless list[1]?
      log_error list[0], 'find code to eval'
    unless (type list[1]) is 'array'
      log_error list[1], 'should be expression here'
    code = main.interpret scope, list[1]
    child =
      parent: code.parent
      outer: scope
    code.list.map (expression) ->
      main.interpret child, expression
  import: (scope, list) ->
    unless list[1]?
      log_error list[0], 'add path to be imported'
    unless (type list[1]) is 'object'
      log_error list[0], 'need argument in string'
    module_path = path.join list[1].file.path, '..', list[1].text
    unless fs.existsSync module_path
      log_error list[1], "no file named #{module_path}"
    main.run scope, (parse module_path)