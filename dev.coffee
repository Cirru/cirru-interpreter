
require('calabash').do 'dev',
  'coffee -o lib/ -wbc coffee/'
  'node-dev test/test.coffee'