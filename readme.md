
Cirru Interpreter
------

An exercise for learning to create a scripting languages.
Based on the syntax of Cirru-Parser.

```
npm install -g cirru-interpreter
```

### Features

`✗` means waiting for implementation, `✓` means done.

* basic data types of ✗
* set/get variables in current scope ✗
* load code and run in a given scope ✗
* pattern matching ✗
* module system ✗
* a live reloading runtime ✗

### Demos

```cirru
-- comment is an expression

-- data types
number 1
bool yes
string this-is-a-string
string "this is a string"
array (number 1) (string string)
hash (key (number 3)) (key (string value))
regex ^hello\sworld$

-- deal with scope
set a (number 1)
get a
print a
-- refer to the parent scope
parent
-- get current scope as hash a reference
get-scope
get-parent
extend-scope a

