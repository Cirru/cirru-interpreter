
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
show = console.log
util = require 'util'
puts = util.print

log = -> console.log '\n', arguments...
# log = -> # toggle

parser = require 'cirru-parser'

has_content = (list) -> list.length > 0

# format JS data types for output
format = (data, history=[]) ->
  log 'formating:', data
  show data
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
      else if obj$ value
        if value in history
          value = {}
        else
          if (obj$ value) and (value.type is 'scope')
            history.push value
          value = format value, history
      ret[key] = value
    log 'format ret:', ret
    ret

source_path = path.join process.env.PWD, process.argv[2]

# scopes are mainly for functions
prototype =
  # store real value here
  value:
    parent: {tag: 'prototype'}
    self: {tag: 'prototype'}
    outer: {tag: 'prototype'}
  search: (key) ->
    log 'searching:', key, @
    if @value[key]?
      @value[key]
    else
      log 'search:', key, @value
      if @value.parent?
        @value.parent.search key
      else
        undefined

  # type of both data and value
  type: 'scope'

  # if it is value, then it has method
  method: {}

  # tag oof id
  tag: 'prototype'

  # core function which evals all code
  read: (exp) ->
    try
      log 'reading:', exp
      head = if str$ exp[0] then (@get exp[0]) else (@read exp[0])
      body = exp.body
      log 'read:', head, body
      if fun$ head.raw
        log 'function:', head
        head.value.outer = @value.outer
        head.raw body, @
      else if obj$ head.value
        while body[0]?
          key = body.shift()
          # log 'here key', key, head
          head = head.get key
        head
      else
        head.method[body[0]]
    catch err
      line = exp.line + 1
      show "Error at #{line}:\t", @code[exp.line]
      throw err

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
      log 'get string:', key, @
      @search key

# functions for self-bootstrap
prototype.value = boots =
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
      log 'set started', body, scope
      value = scope.get body[1]
      log 'value', value
      unless scope.value? then scope.value = {}
      scope.value[body[0]] = value
      log 'set value outer_set', value.value.outer

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
          if obj$ key.raw
            JSON.stringify key.value
          else
            key.raw
        else
          key
      log 'phrase:', value
      ret =
        __proto__: prototype
        type: 'string'
        raw: value.join ' '
        tag: 'phrase'

  # generate list by reading from scope
  array:
    __proto__: prototype
    type: 'function'
    tag: 'array'
    raw: (body, scope) ->
      body.map((key) -> scope.get key)

  # table but with scopes
  ':':
    __proto__: prototype
    type: 'function'
    tag: 'by :'
    raw: (body, scope) ->
      log 'table:', body
      inner_scope = create_scope scope
      inner_scope.value.outer = scope
      while body[0]?
        pair = body.shift()
        log 'pair', pair
        value = inner_scope.get pair[1]
        inner_scope.value[pair[0]] = value
      log 'table with scope:', inner_scope
      inner_scope

  # define a function
  '^':
    __proto__: prototype
    type: 'function'
    tag: 'by ^'
    raw: (body, scope) ->
      log 'lambda:', body
      params = body.shift()
      if str$ params then params = [params]
      f = (inputs, outer_scope) ->
        inner_scope = create_scope scope
        inner_scope.value.outer = outer_scope
        inner_scope.tag = 'inner_scope'
        params.forEach (key, index) ->
          key = scope.word key
          value = outer_scope.get inputs[index]
          inner_scope.value[key] = value
          log 'params set:', key, value
        ret = undefined
        log 'creating inner_scope', inner_scope.value.outer
        log 'the body part:', body
        body.forEach (exp) ->
          log 'the exp', exp
          ret = inner_scope.read exp
        log 'f ret:', ret
        ret
      data =
        __proto__: prototype
        type: 'function'
        tag: 'ret ^'
        raw: f

  '*':
    __proto__: prototype
    type: 'function'
    tag: 'by *'
    raw: (body, scope) ->
      list = body.map (key) -> scope.get key
      list.reduce (x, y) ->
        ret =
          __proto__: prototype
          type: 'number'
          raw: x.raw * y.raw

  char:
    __proto__: prototype
    type: 'function'
    tag: 'char'
    raw: (body, scope) ->
      maps =
        newline: '\n'
        left_bracket: '('
        right_bracket: ')'
      ret =
        __proto__: prototype
        type: 'string'
        value: maps[body[0]]

  comment:
    __proto__: prototype
    tag: 'comment'
    type: 'function'
    raw: ->

create_scope = (scope) ->
  child =
    __proto__: prototype
    value:
      parent: scope
      outer: scope.value.outer
    tag: 'create_scope' + scope.tag

  child.value.self = child

  child

run = (source_filename) ->
  source = fs.readFileSync source_filename, 'utf8'

  {tree, code} = parser.parse source
  tree = tree.filter has_content
  # log 'tree:', tree
  prototype.code = code

  global_scope =
    __proto__: prototype
    tag: 'global_scope'
    value:
      outer: prototype
      parent: prototype
  global_scope.value.self = global_scope
  # log 'reading global_scope', space_scope
  tree.forEach (line) -> global_scope.read line

run source_path
fs.watchFile source_path, interval: 100, ->
  run source_path