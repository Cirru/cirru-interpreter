
{parse, error} = require 'cirru-parser'
{ prelude
, log_error
, print
, stringify
, type } = require './prelude'

root_scope = {}
exports.interpret = interpret = (scope, list) ->
  # print list
  func = list[0].text
  if prelude[func]?
    prelude[func] scope, list
  else if scope[func]?
    scope[func] scope, list
  else
    log_error list[0], "can not found #{stringify list[0].text}"

exports.run = ->
  ast = parse './test/code.cr'
  if ast.errors.length > 0
    console.log ast.errors.join('\n')
  else
    ast.tree.map (line) ->
      try
        interpret root_scope, line if line.length > 0
      catch err
        has_coffee = (text) -> text.indexOf('.coffee') > 0
        print err.stack.split('\n')[..10].join('\n')