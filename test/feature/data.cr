
echo ==== basic data structures

print $ number 3

string x

bool yes

set array-demo $ array
  number 4
  number 3

set hash-demo $ hash
  a (number 2)

regex ^$

print (nil)

print (get-scope)
print hash-demo
print $ at hash-demo (string a)
print $ at array-demo (number 1)