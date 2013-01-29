
Array::__defineGetter__ 'body', -> @[1..]

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
  # console.log '\n\n'
  # console.log arguments...
show = console.log
util = require 'util'
puts = util.print

parser = require 'cirru-parser'

has_content = (list) -> list.length > 0

# format JS data types for output
format = (data) ->
  # log 'formating:', data
  unless data?
    'undefined'
  else if data.raw?
    if fun$ data.raw
      '[function]'
    data.raw
  else
    ret = {}
    for key, value of data.value
      if key in ['parent', 'outer', 'self']
        value = {}
      if obj$ value
        value = format value
      ret[key] = value
    ret

source_path = path.join process.env.PD, process.argv[2]

# scopes are mainly for functions
prototype =
  # outer scope is the scope the function runs
  outer: {}
  outer_set: (dest) -> @outer = dest

  # value and normal parent scopes
  parent: {}
  parent_set: (dest) -> @parent = dest

  # store real value here
  value: {}
  value_set: (key, value) ->
    @value[key] = value
    if value.outer?
      @outer_set @
  value_find: (key) ->
    log 'try finding', key, @value
    if @value[key]?
      @value[key]
    else
      log 'finding', key
      @parent.value_find key

  # type of both data and value
  type: 'scope'

  # if it has value, just be raw value
  raw: undefined

  # core function which evals all code
  read: (exp) ->
    log 'reading:', exp
    head = if str$ exp[0] then (@get exp[0]) else (@read exp[0])
    log 'head:', head
    body = exp.body
    if fun$ head.raw
      log 'function:', head.raw
      self = @
      head.raw body, @
    else
      while body[0]?
        key = body.shift()
        log 'here key', key, head
        head = head.get key
      head

  # get string value from scope
  word: (key) ->
    if str$ key
      key
    else if arr$ key
      @read key

  # get value from scope
  get: (key) ->
    log 'trying to get', key
    if arr$ key
      log 'got array:', key
      @read key
    else if num$ (Number key)
      log 'number', key
      num_obj =
        __proto__: prototype
        type: 'number'
        raw: Number key
    else if str$ key
      # log 'str$', key, @
      @value_find key

boots =
  # echo prints anything passed to it
  echo:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) -> log (format body)

  # for [key], get one value from scope by 'key'
  get:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) -> scope.get body[0]

  # get back string or an expression
  word:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) -> scope.word body[0]

  # read data directly and the function to return
  read:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) -> scope.read body
  data:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      log 'data:', body[0]
      ret =
        __proto__: prototype
        type: 'array'
        raw: body[0]

  # set a key-value pair at scope.value
  set:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      log 'set started', body
      value = scope.get body[1]
      log 'value', value
      scope.value_set body[0], value

  # read value by key and print them
  print:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      # log 'print started'
      body = body.map (key) -> format (scope.get key)
      show body...

  # generate string with JSON.stringify
  string:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      ret =
        __proto__: prototype
        type: 'string'
        raw: body.map(String).join ' '

  # phrase: eval if there are arrays
  phrase:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      list = body.map (key) -> scope.word key
      value = list.map (key) ->
        if obj$ key
          if obj$ key.value
            JSON.stringify key.value
          else
            key.value
        else
          key
      log 'phrase:', value
      ret =
        __proto__: prototype
        type: 'string'
        raw: value.join ' '

  # generate list by reading from scope
  array:
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      body.map((key) -> scope.get key)

  # table but with scopes
  ':':
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      log 'table:', body
      inner_scope = create_scope scope
      while body[0]?
        pair = body.shift()
        log 'pair', pair
        value = inner_scope.get pair[1]
        inner_scope.value_set pair[0], value
      log 'table with scope:', inner_scope
      inner_scope

  # define a function
  '^':
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      log 'lambda:', body
      params = body.shift()
      if str$ params then params = [params]
      f = (inputs, outer_scope) ->
        log 'creating inner_scope'
        inner_scope = create_scope scope
        inner_scope.outer_set scope.outer
        params.forEach (key, index) ->
          key = scope.word key
          value = outer_scope.get inputs[index]
          inner_scope.value_set key, value
          log 'params set:', key, value
        ret = undefined
        log 'the body part:', body
        body.forEach (exp) ->
          log 'the exp', exp, inner_scope
          ret = inner_scope.read exp
        log 'we have ret:', ret
        ret
      data =
        __proto__: prototype
        type: 'function'
        raw: f

  '*':
    __proto__: prototype
    type: 'function'
    raw: (body, scope) ->
      list = body.map (key) -> scope.get key
      list.reduce (x, y) ->
        ret =
          __proto__: prototype
          type: 'number'
          raw: x.raw * y.raw

# the most outside scope
space_scope =
  proto_find: -> null
  value_find: (key) -> boots[key]
  value: boots

create_scope = (scope) ->
  child =
    __proto__: prototype
    parent: scope
    outer: scope
    value:
      outer: scope
      parent: scope

  child.value.self = child

  child

run = (source_filename) ->
  source = fs.readFileSync source_filename, 'utf8'

  {tree, code} = parser.parse source
  tree = tree.filter has_content
  log 'tree:', tree

  global_scope = create_scope space_scope
  # log 'reading global_scope', space_scope
  tree.forEach (line) -> global_scope.read line

run source_path
fs.watchFile source_path, interval: 100, ->
  run source_path