
define (require, exports) ->
  window.show = (args...) -> console.log.apply console, args
  ls = localStorage

  run = require '../script/run.coffee'
  cirru = require '../lib/cirru-editor/script/cirru-editor.coffee'
  $ = require 'jquery'
  draw = require '../script/draw.coffee'

  editor = cirru.editor $('#writer')
  list =
    if ls.list? then (JSON.parse ls.list).value
    else
      ls.list = JSON.stringify value: ['\t']
      ['\t']

  editor.val list
  editor.render()
  editor.reset_history list

  run_code = ->
    code = editor.val()
    $('#debug').empty()
    try
      ret = run.run code
      $('#debug').html (draw.output ret)
    catch err
      $('#debug').text err

  editor.update ->
    ls.list = JSON.stringify value: editor.val()
    run_code()

  $('#debug').click run_code
  $('#writer').click()
  
  return