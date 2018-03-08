#!/usr/bin/env fish
#
# internal-functions
#
# Used by fish-my-aws functions to work with stdin and arguments.

function __fma_read_inputs
  __fma_read_stdin | read -l input
  test -n "$input"; or set -l input $argv
  echo $input                     |\
    sed -E 's/\ +$//'             |\
    sed -E 's/^\ +//'             |\
    tr ' ' '\n'
end

function __fma_read_stdin
  command [ -t 0 ]; or              \
    cat                           | \
    awk '{ print $1 }'            | \
    tr '\n' ' '                   | \
    sed 's/\ $//'
end

function __fma_error
  echo "ERROR: $argv" > /dev/stderr
end

function __fma_usage
  echo "USAGE: $_ $argv" > /dev/stderr
end
