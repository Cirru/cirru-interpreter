
{start} = require './main'

filename = process.argv[2]

if filename?
  start process.argv[2]
else
  console.log '[Error]: no filename specified, exit'