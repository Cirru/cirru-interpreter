
clc = require 'cli-color'
{parse, error} = require 'cirru-parser'
{prelude, cirru_error} = require './prelude'
{print, stringify, type} = require './tool'
{match} = require 'coffee-pattern'

util = require 'util'
fs = require 'fs'

call_stack = []

exports.interpret = interpret = (scope, list) ->
  # print list
  options =
    text: ''
    x: list[0].x
    y: list[0].y
    file: list[0].file
  stamp = error options
  call_stack.unshift {scope, stamp}

  func = list[0].text
  if scope[func]?
    scope[func] scope, list
  else if prelude[func]?
    prelude[func] scope, list
  else
    cirru_error list[0], "not found: #{stringify list[0].text}"

exports.run = (scope, ast) ->
  if ast.errors.length > 0
    print ast.errors.join('\n')
  else
    for line in ast.tree
      call_stack = []
      try
        interpret scope, line if line.length > 0
      catch err
        print clc.bgXterm(130).white "\n#{err}"
        print err.stack.split('\n')[1..7].join('\n')
        call_stack[-4..].map (record) -> util.print record.stamp
        break
  scope or {}

exports.start = (srcpath) ->
  exports.run {}, (parse srcpath)
  require('./prelude').reloading.on 'reload', ->
    console.log '\n ... Reloading From File ... \n'
    exports.run {}, (parse srcpath)

  fs.watchFile srcpath, interval: 200, ->
    require('./prelude').reloading.emit 'reload'