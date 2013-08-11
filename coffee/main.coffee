
{parse, error} = require 'cirru-parser'
libs = require './prelude'
stringify = (object) -> JSON.stringify object, null, 2

print = (xs...) -> console.log xs...

log_error = (token, message) ->
  options =
    text: message
    x: token.x
    y: token.y
    file: token.file
  print error options

ast = parse './test/code.cr'

root_scope = {}

prelude =
  number: (scope, list) ->
    # print 'number:', list
    if not list? or not list[1]
      log_error list[0], 'need number here'
    x = list[1]
    number = parseInt x.text
    if isNaN number
      log_error x, "#{stringify x.text} is not valid number"
    else
      number

interpret = (scope, list) ->
  # print list
  func = list[0].text
  if prelude[func]?
    prelude[func] scope, list
  else if scope[func]?
    scope[func] scope, list
  else
    log_error list[0], "can not found #{stringify list[0].text}"

if ast.errors.length > 0
  console.log ast.errors.join('\n')
else
  ast.tree.map (line) ->
    try
      interpret root_scope, line if line.length > 0
    catch err
      has_coffee = (text) -> text.indexOf('.coffee') > 0
      print err.stack.split('\n').filter(has_coffee).join('\n')