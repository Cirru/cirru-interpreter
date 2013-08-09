
{parse} = require 'cirru-parser'
stringify = (object) -> JSON.stringify object, null, 2

ast = parse '../test/code.cr'
out = ast.error
  text: 'demo'
  x: 1
  y: 1

console.log out