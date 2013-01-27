
Array::__defineGetter__ 'head', -> @[0]
Array::__defineSetter__ 'head', (value) -> @[0] = value

Array::__defineGetter__ 'body', -> @[1..]
Array::__defineGetter__ 'filled', -> @length > 0

Array::__defineGetter__ 'last', -> @[@.length-1]
Array::__defineSetter__ 'last', (value) -> @[@.length-1] = value

Array::remove = (value) ->
  # log 'now', @
  self = @
  [1..@length].forEach ->
    thing = self.shift()
    unless thing is value
      self.push thing
  self

toType = (x) ->
  ret = ({}).toString.call(x).match /\s([a-zA-Z]+)/
  ret[1].toLowerCase()
arr$ = (x) -> (toType x) is 'array'
str$ = (x) -> (toType x) is 'string'
num$ = (x) ->
  rule1 = (toType x) is 'number'
  rule2 = Number.isNaN x
  rule1 and (not rule2)
obj$ = (x) -> (toType x) is 'object'
fun$ = (x) -> (toType x) is 'function'

path = require 'path'
fs = require 'fs'
log = ->
  console.log '\n\n'
  console.log arguments...
util = require 'util'
puts = util.print

parser = require 'cirru-parser'

has_content = (list) -> list.length > 0

all_notes = []
process.on 'exit', -> log all_notes
note = ->
  log arguments
  for key, value of arguments
    unless value in all_notes
      all_notes.push value
  log arguments...

source_path = path.join process.env.PD, process.argv[2]
watching_files = []

# scopes are mainly for functions
scope_prototype =
  # outer scope is the scope the function runs
  outer: {}
  outer_set: (dest) -> @outer = dest

  # the parent Node when an object assigned to another
  root: {}
  root_set: (dest) -> @root = dest

  # value and normal parent scopes
  parent: {}
  parent_set: (dest) -> @parent = dest
  value: {}
  value_set: (key, value) -> @value[key] = value
  value_find: (key) ->
    log 'try finding', key
    if @value[key]?
      @value[key]
    else
      log 'finding', key
      @parent.value_find key

read = (table, scope) ->
  log 'reading::', table

  head = scope.value_find table.head
  body = table.body
  log 'head:', table.head, head, body
  if arr$ head
    head = read head, scope
  if fun$ head
    return head body, scope
  else if obj$ head
    if head.__proto__ is scope_prototype
      if body.head?
        key = body.shift()
        key_name = boots.word [key], scope
        head = boots.get [key_name], scope
        if body.filled?
          head
        else
          body.unshift head
          read body, scope
  return head

boots =
  # echo prints anything passed to it
  echo: (body, scope) -> puts body..., '\n'

  # for [key], get one value from scope by 'key'
  get: (body, scope) ->
    key = body.head
    if arr$ key
      read key, scope
    else if num$ (Number key)
      log 'number', key
      Number key
    else if str$ key
      scope.value_find key
    else
      throw new Error "Cant get #{key}"

  # set a key-value pair at scope.value
  set: (body, scope) ->
    log 'set started'
    key = body.shift()
    value_name = body.shift()
    scope.value_set key, (boots.get [value_name], scope)

  # read value by key and print them
  print: (body, scope) ->
    # log 'print started'
    log ''
    body.forEach (key) ->
      log 'trying to print', key
      ret = boots.get [key], scope
      log 'ret:: ', ret
      puts ret
      puts '\t'
    puts '\n'

  # generate string with JSON.stringify
  string: (body, scope) ->
    body.map(JSON.stringify).join ' '

  # get back string or an expression
  word: (body, scope) ->
    key = body.shift()
    if str$ key
      key
    else if arr$ key
      read key, scope
    else
      throw new throw "what could #{key} be?"

  # phrase: eval if there are arrays
  phrase: (body, scope) ->
    body.map((key) -> boots.word [key], scope).join ' '

  # generate list by reading from scope
  array: (body, scope) ->
    body.map((key) -> boots.get [key], scope)

  # table but with scopes
  ':': (body, scope) ->
    inner_scope = create_scope scope
    while body.head
      pair = body.shift()
      key_name = pair.shift()
      key = boots.word [key_name], inner_scope
      value_name = pair.shift()
      value = boots.get [value_name], inner_scope
      inner_scope.value_set key, value
    log 'table with scope:', inner_scope.value
    inner_scope.value

  # define a function
  '^': (body, scope) ->
    params = body.shift()
    if str$ params then params = [params]
    make_fun = (inputs, outer_scope) ->
      log 'creating inner_scope'
      do ret_fun = (inputs, scope) ->
        inner_scope = create_scope scope
        if params.filled
          key = params.shift()
          key_name = inputs.shift()
          value = boots.get [key_name], outer_scope
          inner_scope.value_set key, value
          inner_scope.outer_set scope.outer
          ret_fun inputs, inner_scope
        else
          ret = undefined
          body.forEach (expression) ->
            log 'the expression', expression, inner_scope
            ret = read expression, inner_scope
          log 'we have ret:', ret
          ret

  '*': (body, scope) ->
    list = body.map (key) -> boots.get [key], scope
    list.reduce (x, y) -> x * y

# the most outside scope
space_scope =
  proto_find: -> null
  root_find: -> null
  value_find: (key) -> boots[key]

create_scope = (scope) ->
  child =
    __proto__: scope_prototype
    parent: scope
    root: scope.value
    outer: scope.value

  child.value =
    outer: child.outer
    parent: child.parent
    root: child.root

  child.value.value = child.value

  child

run = (source_filename) ->
  source = fs.readFileSync source_filename, 'utf8'

  {tree, code} = parser.parse source
  tree = tree.filter has_content
  log 'tree:', tree

  global_scope = create_scope space_scope
  global_scope.value = boots
  # log 'reading global_scope', space_scope
  tree.forEach (line) -> read line, global_scope

run source_path
fs.watchFile source_path, interval: 100, ->
  run source_path