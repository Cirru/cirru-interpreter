
{print} = require '../coffee/format'

print 1, 3, 4, 'string', /a/

print null, null

print (new Date)

print (new Error 'this is an error')

print [1, [1, [1]]]

print a: 1, b: {a: 1, b: {a: 2}}

print [1, {a: {x: [1, 2]}}]

print date: (new Date)
print [(new Date), /1/]