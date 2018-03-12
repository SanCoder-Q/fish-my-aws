#!/usr/local/bin/fish

set SOURCE_DIR (dirname (status -f))
set ROOT_DIR $SOURCE_DIR/..

function __fma_trim_json_extension
  sed 's@\.json[^\s\S]\{0,1\}$@@'
end

function __fma_with_exist_stack_name -a cmd
  __fma_complete_with_subcommand $cmd '(fma stacks)'
end

function __fma_with_local_stack_name -a cmd
  __fma_complete_with_subcommand $cmd '(__fish_complete_suffix json | __fma_trim_json_extension)' '_(test|dev|staging|prod)'
end

__fma_complete_subcommand stacks 'list all stacks'

__fma_complete_subcommand stack-create 'create a stack based on name'
__fma_with_local_stack_name stack-create

__fma_complete_subcommand stack-cancel-update 'cancel an update'
__fma_with_exist_stack_name stack-cancel-update

__fma_complete_subcommand stack-update 'update a stack based on name'
__fma_with_exist_stack_name stack-update

__fma_complete_subcommand stack-delete 'delete a stack based on name'
__fma_with_exist_stack_name stack-delete

__fma_complete_subcommand stack-exports 'returns key, value pairs for exports from *all* stacks'

__fma_complete_subcommand stack-recreate 'recreate the stack files based on the current stack'
__fma_with_exist_stack_name stack-recreate

__fma_complete_subcommand stack-failure 'get failed reason based on stack'
__fma_with_exist_stack_name stack-failure

__fma_complete_subcommand stack-events 'get CloudFormation events base on stack name'
__fma_with_exist_stack_name stack-events

__fma_complete_subcommand stack-resources 'list all the resources regarding to a stack'
__fma_with_exist_stack_name stack-resources

__fma_complete_subcommand stack-asgs 'list all the auto scaling groups of a stack'
__fma_with_exist_stack_name stack-asgs

__fma_complete_subcommand stack-elbs 'list all the elastic load balancers of a stack'
__fma_with_exist_stack_name stack-elbs

__fma_complete_subcommand stack-instances 'list all the EC2 instances of a stack'
__fma_with_exist_stack_name stack-instances

__fma_complete_subcommand stack-parameters 'list the parameters of a stack'
__fma_with_exist_stack_name stack-parameters

__fma_complete_subcommand stack-status 'get the current status of a stack'
__fma_with_exist_stack_name stack-status

__fma_complete_subcommand stack-tail 'get real time events of a stack until COMPLETE or FAILED'
__fma_with_exist_stack_name stack-tail

__fma_complete_subcommand stack-template 'get the template of a stack'
__fma_with_exist_stack_name stack-template

__fma_complete_subcommand stack-outputs 'get the outputs of a stack'
__fma_with_exist_stack_name stack-outputs

__fma_complete_subcommand stack-diff 'diff between the current stack and local stack file'
__fma_with_exist_stack_name stack-diff
