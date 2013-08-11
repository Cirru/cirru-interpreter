
{error} = require 'cirru-parser'

exports.type = type = (x) ->
  Object::toString.call(x)[1...-1].split(' ')[1].toLowerCase()

exports.stringify = stringify = (object) ->
  JSON.stringify object, null, 2

exports.print = print = (xs...) -> console.log xs...

exports.log_error = log_error = (token, message) ->
  options =
    text: message
    x: token.x
    y: token.y
    file: token.file
  print error options

exports.prelude =
  number: (scope, list) ->
    # print 'number:', list
    unless list? and list[1]?
      log_error list[0], 'need number here'
    x = list[1]
    number = parseInt x.text
    if isNaN number
      log_error x, "#{stringify x.text} is not valid number"
    else
      number
  bool: (scope, list) ->
    unless list? and list[1]?
      log_error list[0], 'need bool symbol here'
    x = list[1]
    if x.text in ['yes', 'true', 'on', 'ok', 'right']
      yes
    else if x.text in ['no', 'false', 'off', 'wrong']
      no
    else
      log_error x, "#{stringify x.text} is not a valid bool"
  string: (scope, list) ->
    unless list? and list[1]?
      log_error list[0], 'need string here'
    x = list[1]
    list[1].text