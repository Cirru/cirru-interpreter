
clc = require 'cli-color'
util = require 'util'
moment = require 'moment'
{match} = require 'coffee-pattern'
{type} = require './tool'

line_head = yes
empty_line = no

log_indentation = ''
newline = ->
  util.print '\n'
  util.print log_indentation
  empty_line = (line_head is yes)
  line_head = yes

indent = ->
  log_indentation += '  '
dedent = ->
  log_indentation = log_indentation[...-2]

write_char = (item) ->
  util.print item
  line_head = no
  empty_line = no
write_string = (item) ->
  util.print ' ' unless line_head
  write_char item

write = (item) ->
  the_type = type item
  match the_type,
    number: ->
      write_string (clc.blue item)
    string: ->
      text = clc.black.bgYellow item
      quote = clc.yellow '"'
      write_string (quote + text + quote)
    regexp: ->
      write_string (clc.xterm(32) item )
    null: ->
      write_string (clc.xterm(130) 'nil')
    date: ->
      time = moment(item).format('YYYY MM-DD HH:mm')
      write_string (clc.bgXterm(20).xterm(39) time)
    error: ->
      write_string (clc.bgXterm(130).black item)
    array: ->
      newline() unless empty_line or line_head
      write_char (clc.xterm(22) '⤷')
      indent()
      for value in item
        newline()
        write value
      dedent()
    object: ->
      # newline() unless empty_line or line_head
      write_char (clc.xterm(22) '⤵')
      indent()
      for key, value of item
        newline() unless empty_line or line_head
        write_string (clc.bgXterm(52) key)
        write_char (clc.xterm(52) ':')
        write value
      dedent()
    undefined, ->
      write_string (clc.bgXterm(153).white item)

exports.print = (xs...) ->
  log_indentation = ''
  newline() unless empty_line
  empty_line = no
  newline()
  xs.map write
  empty_line = no