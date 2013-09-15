
clc = require 'cli-color'
util = require 'util'
moment = require 'moment'
{match} = require 'coffee-pattern'
{type} = require './tool'

write = (item) ->
  the_type = type item
  match the_type,
    number: -> clc.blue item
    string: ->
      text = clc.black.bgYellow item
      quote = clc.yellow '"'
      quote + text + quote
    regexp: -> clc.xterm(32) item 
    null: -> clc.xterm(130) 'nil'
    date: ->
      time = moment(item).format('YYYY MM-DD HH:mm')
      clc.bgXterm(20).xterm(39) time
    error: ->
      clc.bgXterm(130).black item
    array: ->
      pair = (value) -> (clc.xterm(22) '* ') + (write value)
      item.map(pair).join('\n')
    object: ->
      pair = (value, key) -> key + ': ' + (write value) + '\n'
      buffer = ''
      buffer += (pair value, key) for key, value of item
      buffer
    undefined, ->
      clc.bgXterm(153).white item

exports.print = (xs...) ->
  console.log (xs.map write).join('\t')