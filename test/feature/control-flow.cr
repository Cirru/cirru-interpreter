
echo ==== testing control flows

set a $ number 1
set b $ number 2
set c $ number 1

if (equal a b)
  echo a equals b
  echo a not equals b

if (equal a c)
  echo a is c

if (equal c b)
  echo b is c

print $ begin
  print (number 1)
  string somthing
  number 0