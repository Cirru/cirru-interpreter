
number 3

string x

bool yes

array (number 4) 3

hash (a (number 2))

regex ^$

set variable (number 1)

get variable

print (number 3)

echo (get-scope)

set child (hash (key (number 3)))
load-scope child (print 5)

under child
  print $ get key
  echo $ get parent

set c $ code
  print 1
  echo (get parent)
  echo (get outer)
eval (get c)

include ./lib.cr

assert (equal (bool no) (bool yes)) (string "show print this")