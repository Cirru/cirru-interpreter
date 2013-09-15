
bash = require('calabash')

bash.add 'dev',
  'node-dev test/test.coffee'

bash.add 'publish',
  'coffee -o lib/ -wbc coffee/'

bash.add 'test log',
  'node-dev test/logs.coffee'

bash.go()