
number 3

string x

bool yes

array (number 4) (number 3)

hash (a (number 2))

regex ^$

set variable (number 1)

get variable

print (number 3)

echo (get-scope)

set child (hash (key (number 3)))
load-scope child (print (string 5))

under child
  print $ get key
  echo $ get parent

set c $ code
  print (number 1)
  echo (get parent)
  echo (get outer)
eval (get c)

assert (equal (bool right) (bool yes)) (string "show print this")

print $ require ./module.cr
print $ require ./module.cr
print $ require ./module.cr

print (string aa)