
exports.type = (x) ->
  Object::toString.call(x)[1...-1].split(' ')[1].toLowerCase()

exports.stringify = (object) ->
  JSON.stringify object, null, 2

exports.print = (xs...) ->
  console.log xs...

exports.write = (xs...) ->
  require('util').print xs...

exports.assert = (xs...) ->
  console.assert xs...