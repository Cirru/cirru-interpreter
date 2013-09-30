
fs = require 'fs'
{start} = require '../coffee/main'

start './test/code.cr'
fs.watchFile './test/code.cr', interval: 100, ->
  stamp = (new Date).toString()
  console.log stamp.match(/\d+:\d+:\d+/)[0]
  start './test/code.cr'