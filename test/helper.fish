#!/usr/local/bin/fish

set SOURCE_DIR (dirname (status -f))
set ROOT_DIR $SOURCE_DIR/..

set -l fish_tank /usr/local/share/fish-tank/tank.fish
if not test -e $fish_tank
  echo 'Install fish-tank for running the tests (https://github.com/terlar/fish-tank)'
  git clone --depth 1 https://github.com/terlar/fish-tank.git /tmp/fish-tank
  cd /tmp/fish-tank/
  make install
end

source $fish_tank

for f in $ROOT_DIR/lib/*functions.fish
  source $f
end

set -U tank_reporter spec
