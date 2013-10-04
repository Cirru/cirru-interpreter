
set variable (number 1)

get variable

print (number 3)

echo (get-scope)

set child (hash (key (number 3)))
load-scope child (print (string 5))

under child
  print $ get key
  echo $ get parent