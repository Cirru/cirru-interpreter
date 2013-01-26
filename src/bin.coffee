
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

str$ = (x) -> x instanceof String
arr$ = (x) -> x instanceof Array
num$ = (x) -> x instanceof Number
obj$ = (x) -> x instanceof Object
fun$ = (x) -> x instanceof Function

path = require 'path'
fs = require 'fs'
log = ->
  console.log '\n\n'
  console.log arguments...
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

scope_prototype =
  outer: {}
  outer_set: (dest) -> @outer = dest
  outer_find: (key) ->
    if @outer.value[key]?
      @outer.value[key]
    else
      @outer.outer_find key

  proto: {}
  proto_set: (dest) -> @proto = dest
  proto_find: (key) ->
    if @value[key]?
      @value[key]
    else
      @proto.proto_find? key

  root: {}
  root_set: (dest) -> @root = dest
  root_find: (key) ->
    if @value[key]?
      @value[key]
    else
      @root.root_find? key

  parent: {}
  parent_set: (dest) -> @parent = dest

  value:
    '@': @proto
    '#': @outer
    '!': @parent
  value_set: (key, value) -> @value[key] = value
  value_find: (key) ->
    if @value[key]?
      @value[key]
    else
      @parent.parent_find? key

create_scope = (scope) ->
  child =
    __proto__: scope_prototype
    parent: scope
    proto: scope
    outer: scope
    root: scope

read = (table, scope) ->
  log 'reading::', table, scope

  head = scope.value_find table.head
  body = table.body
  log 'head:', table.head, head, body
  if arr$ head
    head = read head, scope
  if fun$ head
    head body, scope
  else
    if body.filled
      head[body]
    else
      head

boots =
  echo: (body, scope) -> log body...
  set: (body, scope) ->

run = (source_filename) ->
  source = fs.readFileSync source_filename, 'utf8'

  {tree, code} = parser.parse source
  tree = tree.filter has_content
  log 'tree:', tree

  global_scope = create_scope {}
  global_scope.value = boots
  tree.forEach (line) -> read line, global_scope

  fs.unwatchFile source_filename
  fs.watchFile source_filename, interval: 100, ->
    run source_filename

log 'running'
run source_path