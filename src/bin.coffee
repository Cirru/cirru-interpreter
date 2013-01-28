
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
  console.log '\n\n'
  console.log arguments...
util = require 'util'
puts = util.print

parser = require 'cirru-parser'

has_content = (list) -> list.length > 0

# format JS data types for output
format = (data) ->
  item = data.value
  if str$ item
    ret = "\"#{item}\""
  else if arr$ item
    list = item.map (key) ->
      # log 'mapping', key
      format key.value
    ret = "[#{list.join ','}]"
  else if obj$ item
    json = []
    for key, value of item
      unless key in ['parent', 'outer', 'root', 'value']
        json.push "#{key}:#{format value}"
    ret = "{#{json.join ', '}}"
  else if fun$ item
    ret = '[Function]'
  else
    ret = String item
  ret

source_path = path.join process.env.PD, process.argv[2]

# scopes are mainly for functions
prototype =
  # outer scope is the scope the function runs
  outer: {}
  outer_set: (dest) -> @outer = dest

  # the parent Node when an object assigned to another
  root: {}
  root_set: (dest) -> @root = dest

  # value and normal parent scopes
  parent: {}
  parent_set: (dest) -> @parent = dest

  # store real value here
  value: {}
  value_set: (key, value) -> @value[key] = value
  value_find: (key) ->
    log 'try finding', key, @value
    if @value[key]?
      @value[key]
    else
      log 'finding', key
      @parent.value_find key

  # type of both data and value
  type: 'scope'

  # core function which evals all code
  read: (exp) ->
    log 'reading:', exp
    head = if str$ exp[0] then (@get exp[0]) else (@read exp[0])
    log 'head:', head
    body = exp.body
    if fun$ head
      log 'function:', head
      self = @
      head body, @
    else
      while body[0]?
        key = body.shift()
        log 'here key', key
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
        value: Number key
        type: 'number'
    else if str$ key
      # log 'str$', key, @
      @value_find key

boots =
  # echo prints anything passed to it
  echo: (body, scope) -> log (format body)

  # for [key], get one value from scope by 'key'
  get: (body, scope) -> scope.get body[0]

  # get back string or an expression
  word: (body, scope) -> word body[0], value

  # read data directly and the function to return
  read: (body, scope) -> scope.read body
  raw: (body, scope) ->
    log 'raw:', body[0]
    {type: 'array', value: body[0]}

  # set a key-value pair at scope.value
  set: (body, scope) ->
    log 'set started', body
    value = scope.get body[1]
    log 'value', value
    scope.value_set body[0], value

  # read value by key and print them
  print: (body, scope) ->
    # log 'print started'
    body.forEach (key) ->
      ret = scope.get key
      log 'ret', ret
      log (format ret)

  # generate string with JSON.stringify
  string: (body, scope) ->
    ret =
      type: 'string'
      value: body.map(String).join ' '

  # phrase: eval if there are arrays
  phrase: (body, scope) ->
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
      type: 'string'
      value: value.join ' '

  # generate list by reading from scope
  array: (body, scope) ->
    body.map((key) -> scope.get key)

  # table but with scopes
  ':': (body, scope) ->
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
  '^': (body, scope) ->
    log 'lambda:', body
    params = body.shift()
    if str$ params then params = [params]
    (inputs, outer_scope) ->
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

  '*': (body, scope) ->
    list = body.map (key) -> scope.get key
    list.reduce (x, y) ->
      ret =
        type: 'number'
        value: x.value * y.value

# the most outside scope
space_scope =
  proto_find: -> null
  root_find: -> null
  value_find: (key) -> boots[key]

create_scope = (scope) ->
  child =
    __proto__: prototype
    parent: scope
    root: scope
    outer: scope
    value:
      outer: scope
      parent: scope
      root: scope

  child

run = (source_filename) ->
  source = fs.readFileSync source_filename, 'utf8'

  {tree, code} = parser.parse source
  tree = tree.filter has_content
  log 'tree:', tree

  global_scope = create_scope space_scope
  global_scope.value = boots
  # log 'reading global_scope', space_scope
  tree.forEach (line) -> global_scope.read line

run source_path
fs.watchFile source_path, interval: 100, ->
  run source_path