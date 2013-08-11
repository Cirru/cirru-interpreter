
fs = require 'fs'
{run} = require '../coffee/main'

do run
fs.watchFile './test/code.cr', interval: 100, ->
  stamp = (new Date).toString()
  console.log  stamp.match(/\d+:\d+:\d+/)[0]
  do run