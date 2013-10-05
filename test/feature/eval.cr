
echo ==== eval and code

set c $ code
  print (number 1)

print $ eval c

assert
  equal (bool right) (bool yes)
  string "show print this"
