
{print} = require '../coffee/format'

print 1, 3, 4, 'string', /a/

print null, null

print (new Date)

print (new Error 'this is an error')

print [1,2, [1,2, [1, 2]]]

print a: 1, b: '2', {a: 1, b: {a: 2}}