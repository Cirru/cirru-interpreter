
cd `dirname $0`
echo '-- start watching'

stylus -o page/ -w src/*styl &
jade -O page/ -wP src/*jade &
doodle page/ script/ src/test.coffee &

read

pkill -f jade
pkill -f stylus
pkill -f doodle

echo '-- stop watching'