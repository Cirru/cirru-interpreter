
echo ==== eval and code

set c $ code
  print (number 1)

print $ eval c

assert
  equal (bool right) (bool yes)
  string "show print this"

set pseudo-func $ code
  set a $ at parent $ at args $ number 1
  set b $ at parent $ at args $ number 2
  add a b


set num-a $ number 3
set num-b $ number 4

print $ call pseudo-func num-a num-b