
number 3

string x

bool yes

array (number 4) 3

hash (a (number 2))

regex ^$

set variable (number 1)

get variable

print (number 3)

print (get-scope)

set child (hash (key (number 3)))
load-scope child (print 5)

under child
  print $ get key
  print $ get parent

set c $ code
  print 1
  print (get parent)
  print (get outer)
eval (get c)

import ./lib.cr