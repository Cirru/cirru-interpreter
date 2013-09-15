
{parse, error} = require 'cirru-parser'
{ prelude
, log_error
, print
, stringify
, type } = require './prelude'

root_scope = {}
call_stack = []

exports.interpret = interpret = (scope, list) ->
  # print list
  options =
    text: ''
    x: list[0].x
    y: list[0].y
    file: list[0].file
  stamp = error options
  call_stack.push {scope, stamp}
  func = list[0].text
  if prelude[func]?
    prelude[func] scope, list
  else if scope[func]?
    scope[func] scope, list
  else
    log_error list[0], "can not found #{stringify list[0].text}"

exports.run = (scope, ast) ->
  scope = scope or root_scope
  ast = ast or (parse './test/code.cr')
  if ast.errors.length > 0
    console.log ast.errors.join('\n')
  else
    ast.tree.map (line) ->
      try
        interpret scope, line if line.length > 0
      catch err
        call_stack.map (record) -> print record.stamp
        print '...'
        has_coffee = (text) -> text.indexOf('.coffee') > 0
        print err.stack.split('\n')[..10].join('\n')