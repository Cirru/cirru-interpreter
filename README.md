
Cirru Interpreter
------

An exercise for learning to create a scripting languages.
Based on the syntax of Cirru-Parser.

```
npm install -g cirru-interpreter
```

### Features

`✗` means waiting for implementation, `✓` means done.

* comment

```
✗ -- nothing
```

* basic data types

```
✓ number 1
✓ bool yes
✓ string this-is-a-string
✓ string "this is a string"
✓ array (number 1) (string string)
✓ hash (key (number 3)) (key (string value))
✓ regex ^hello\sworld$
✗ nil
```

* set/get variables in current scope

```
✓ set a (number 1)
✓ get a
✓ print a
✓ get-scope
✓ get-parent
✓ parent
✗ outer
✗ extend-scope a
```

* load code and run in a given scope

```
✓ load a (print 3)
✓ under a (print 3)
✓ code (print x)
✓ eval (get code)
```

* pattern matching

```
✗ match a (string s) (print "it is s")
```

* module system

```
✓ require ./b
```

* a live reloading runtime

```
✗ print a
```