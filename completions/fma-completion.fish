#!/usr/local/bin/fish

set SOURCE_DIR (dirname (status -f))
set ROOT_DIR $SOURCE_DIR/..

function __fma_need_subcommand
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 1 ]
    return 0
  end
  return 1
end

function __fma_with_subcommand
  set cmd (commandline -obc)
  if [ (count $cmd) -gt 1 ]; and [ $argv[1] = $cmd[2] ]
    return 0
  end
  return 1
end

function __fma_complete_subcommand -a sub_command description
  complete -c fma -x -n '__fma_need_subcommand' -a "$sub_command\t'$description'"
end

function __fma_complete_with_subcommand -a sub_command cmd description
  complete -c fma -x -n "__fma_with_subcommand $sub_command" -a "$cmd\t'$description'"
end


complete -c fma -e
complete -c fma -x

source $SOURCE_DIR/stack-completion.fish
source $SOURCE_DIR/s3-completion.fish
