
define (require, exports) ->

  exports.run = (list) ->
    show list
    list.join ' % '
    [1,2,3,4]

  return