
define (require, exports) ->

  exports.output = (list) ->
    show 'output', list
    ret = list.map(String).join('<br>')
    # show ret
    # ret

  return