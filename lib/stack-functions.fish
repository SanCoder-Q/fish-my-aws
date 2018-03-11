#!/usr/bin/env fish -x
#
# stack-functions

##
# Suggested stack/template/params naming conventions
# These are completely optional.
#
#   stack   : token-env
#   template: token.json
#   params  : token-params-env.json
#
# Where:
#
#   token : describes the resources (mywebsite, vpc, bastion, etc)
#   env   : environment descriptor (dev, test, prod, etc)
#
# Following these (entirely optional) conventions means bashn-my-aws can
# infer template & params file from stack name
#
# e.g. stack-create mywebsite-test
#
#      is equivalent (if files present) to:
#
#      stack-create mywebsite-test mywebsite.json mywebsite-params-test.json
#
# Other benefits include:
#
# * ease in locating stack for template (and vice versa) based on name
# * template and params files are listed together on filesystem
# * stack name env suffixes protect against accidents (wrong account error)
# * supports prodlike non-prod environments through using same template
#
# And don't forget, these naming conventions are completely optional.
##

# List CF stacks
#
# To make it fly we omit stacks with status of DELETE_COMPLET

function stacks
  aws cloudformation list-stacks                      \
    --stack-status                                    \
      CREATE_COMPLETE                                 \
      CREATE_FAILED                                   \
      CREATE_IN_PROGRESS                              \
      DELETE_FAILED                                   \
      DELETE_IN_PROGRESS                              \
      ROLLBACK_COMPLETE                               \
      ROLLBACK_FAILED                                 \
      ROLLBACK_IN_PROGRESS                            \
      UPDATE_COMPLETE                                 \
      UPDATE_COMPLETE_CLEANUP_IN_PROGRESS             \
      UPDATE_IN_PROGRESS                              \
      UPDATE_ROLLBACK_COMPLETE                        \
      UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS    \
      UPDATE_ROLLBACK_FAILED                          \
      UPDATE_ROLLBACK_IN_PROGRESS                     \
    --query "StackSummaries[][ StackName ]"           \
    --output text                                    |\
      sort
end

function stack-cancel-update
  set -l stack (_stack_name_arg (__fma_read_inputs $argv))
  command [ -z $stack ]; and __fma_usage "stack"; and return 1

  aws cloudformation cancel-update-stack --stack-name $stack
end

function stack-create
  # type: action
  # create a new stack
  set -l inputs (__fma_read_inputs $argv)
  set -l stack (_stack_name_arg $inputs)
  test -z "$stack"; and __fma_usage "stack [template-file] [parameters-file]"; and return 1

  set -l template (_stack_template_arg $inputs)
  if not test -f "$template"
    echo "Could not find template ($template). You can specify alternative template as second argument."
    return 1
  end
  set -l params (_stack_params_arg $inputs)
  if test -n "$params";
    set parameters "--parameters file://$params"
  end

  sh -c "aws cloudformation create-stack         \
    --stack-name $stack                          \
    --template-body file://$template             \
    $parameters                                  \
    --capabilities CAPABILITY_NAMED_IAM          \
    --disable-rollback"
  and stack-tail $stack
end

function stack-update
  # update an existing stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg  $inputs)
  test -z $stack; and __fma_usage "stack [template-file] [parameters-file]"; and return 1

  set template (_stack_template_arg $inputs)
  if not test -f "$template"
    echo "Could not find template ($template). You can specify alternative template as second argument."
    return 1
  end
  set params (_stack_params_arg $inputs)
  if test -n "$params"; set parameters "--parameters file://$params"; end

  if aws cloudformation update-stack   \
    --stack-name $stack                \
    --template-body "file://$template" \
    $parameters                        \
    --capabilities CAPABILITY_NAMED_IAM
    stack-tail $stack
  end
end

function stack-delete
  # type: action
  # delete an existing stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z "$stack"; and __fma_usage "stack"; and return 1

  if aws cloudformation delete-stack --stack-name $stack
    stack-tail $stack
  end
end

# Returns key,value pairs for exports from *all* stacks
# This breaks from convention for (fi|ba)sh-my-aws functions
# TODO Find a way to make it more consistent
function stack-exports
  aws cloudformation list-exports     \
    --query 'Exports[].[Name, Value]' \
    --output text                    |\
  column -t
end

function stack-recreate
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z "$stack"; and __fma_usage "stack"; and return 1

  set -l tmpdir (mktemp -d /tmp/fish-my-aws.XXXX)
  cd $tmpdir
  echo (stack-template $stack) > $stack.json
  echo (stack-parameters $stack) > $stack-params.json
  stack-delete $stack
  stack-create $stack
  # rm -fr $tmpdir
end

function stack-failure
  # type: detail
  # return the reason a stack failed to update/create/delete
  # FIXME: only grab the latest failure
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z "$stack"; and __fma_usage "stack"; and return 1

  aws cloudformation describe-stack-events \
    --stack-name $stack                    \
    --query "
      StackEvents[?contains(ResourceStatus,'FAILED')].[
        PhysicalResourceId,
        Timestamp,
        ResourceStatusReason
      ]"                                   \
    --output text
end

function stack-events
  # type: detail
  # return the events a stack has experienced
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z "$stack"; and __fma_usage "stack"; and return 1

  if set output (aws cloudformation describe-stack-events \
    --stack-name stack                                    \
    --query "
      sort_by(StackEvents, &Timestamp)[].[
        Timestamp,
        LogicalResourceId,
        ResourceType,
        ResourceStatus
      ]"                                                  \
    --output table)
    echo "$output" | uniq -u
  else
    return $status
  end
end

function stack-resources
  # type: detail
  # return the resources managed by a stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z $stack; and __fma_usage "stack"; and return 1

  aws cloudformation describe-stack-resources                       \
    --stack-name $stack                                             \
    --query "StackResources[].[ PhysicalResourceId, ResourceType ]" \
    --output text
end

function stack-asgs
  # type: detail
  # return the autoscaling groups managed by a stack
  stack-resources $argv | grep "AWS::AutoScaling::AutoScalingGroup"
end

function stack-elbs
  # type: detail
  # return the elastic load balancers managed by a stack
  stack-resources $argv | grep "AWS::ElasticLoadBalancing::LoadBalancer"
end

function stack-instances
  # type: detail
  # return the instances managed by a stack
  set instance_ids (stack-resources $argv | grep "AWS::EC2::Instance" | cut -f1)
  test -n "$instance_ids"; and instances $instance_ids
end

function stack-parameters
  # return the parameters applied to a stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z $stack; and __fma_usage "stack"; and return 1

  aws cloudformation describe-stacks                        \
    --stack-name $stack                                     \
    --query 'sort_by(Stacks[].Parameters[], &ParameterKey)' \
    --output json                                          |\
    jq --sort-keys .
end

function stack-status
  # type: detail
  # return the current status of a stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z $stack; and __fma_usage "stack"; and return 1

  aws cloudformation describe-stacks                   \
    --stack-name $stack                                \
    --query "Stacks[][ [ StackName, StackStatus ] ][]" \
    --output text                                     |\
    column -s "\t" -t
end

function stack-tail
  # type: detail
  # follow the events occuring for a stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z "$stack"; and __fma_usage "stack"; and return 1

  set current
  set final_line
  set output
  set previous
  while not echo \n$current | tail -1 | egrep -q "$stack.*_(COMPLETE|FAILED)"
    if not set output (stack-events "$inputs")
      # Something went wrong with stack-events (like stack not known)
      return 1
    end
    if test -z "$output"; sleep 1; continue; end

    set current (echo \n$output | sed '$d')
    set final_line (echo \n$output | tail -1)
    if test -z "$previous"
      printf "%s\n" $current
    else if test "$current" != "$previous"
      comm -13 (printf "%s\n" $previous | psub) (printf "%s\n" $current | psub)
    end
    set previous $current
    sleep 1
  end
  echo $final_line
end

function stack-template
  # type: detail
  # return the template applied to a stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  aws cloudformation get-template   \
    --stack-name $stack             \
    --query TemplateBody | jq --raw-output --sort-keys .
end

function stack-outputs
  # type: detail
  # return the outputs of a stack
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z $stack; and __fma_usage "stack"; and return 1

  aws cloudformation describe-stacks \
    --stack-name $stack              \
    --query 'Stacks[].Outputs[]'     \
    --output text                   |\
    column -s "\t" -t
end

function stack-validate
  # type: detail
  # validate a json stack template
  set inputs (__fma_read_inputs $argv | cut -f1)
  test -z "$inputs"; and __fma_usage "template-file"; and return 1
  set size (wc -c <"$inputs")
  if test $size -gt 51200
    # TODO: upload s3 + --template-url
    __fma_error "template too large: $size bytes, 51200 max"
    return 1
  else
    aws cloudformation validate-template \
      --template-body file://$inputs
  end
end

function stack-diff
  # type: detail
  # return differences between a template and Stack
  set inputs (__fma_read_inputs $argv)
  test -z "$inputs"; and __fma_usage "stack [template-file]"; and return 1
  _stack_diff_template $inputs
  echo
  _stack_diff_params $inputs
end

#
# Requires jq-1.4 or later # http://stedolan.github.io/jq/download/
#
function _stack_diff_template
  # report changes which would be made to stack if template were applied
  test -z "$argv[1]"; and __fma_usage "stack [template-file]"; and return 1
  _stack_name_arg $argv | read stack
  if not aws cloudformation describe-stacks --stack-name $stack 1>/dev/null
    return 1;
  end
  _stack_template_arg $stack $argv[2] | read template
  if not test -f "$template"
    echo "Could not find template ($template)." >&2
    echo "You can specify alternative template as second argument." >&2
    return 1
  end
  if test (command type -P colordiff)
    set DIFF_CMD colordiff
  else
    set DIFF_CMD diff
  end

  eval $DIFF_CMD -u                          \
    --label stack                            \
      (aws cloudformation get-template       \
         --stack-name $stack                 \
         --query TemplateBody               |\
         jq --sort-keys . | psub)            \
     --label $template                       \
       (jq --sort-keys . $template | psub)

  if test $status -eq 0
    echo "template for stack ($stack) and contents of file ($template) are the same" >&2
  end
end

#
# Requires jq-1.4 or later # http://stedolan.github.io/jq/download/
#
function _stack_diff_params
  # report on what changes would be made to stack by applying params
  test -z "$argv[1]"; and __fma_usage "stack [template-file]"; and return 1
  set stack (_stack_name_arg $argv)
  if not aws cloudformation describe-stacks --stack-name $stack 1>/dev/null
    return 1
  end
  set template (_stack_template_arg $stack $argv[2])
  if test ! -f "$template"
    echo "Could not find template ($template). You can specify alternative template as second argument." >&2
    return 1
  end
  set params (_stack_params_arg $stack $template $argv[3])
  if test -z "$params"
    echo "No params file provided. Skipping" >&2
    return 0
  end
  if test ! -f "$params"
    return 1
  end
  if test (command type -P colordiff)
    set DIFF_CMD=colordiff
  else
    set DIFF_CMD=diff
  end

  eval $DIFF_CMD -u                              \
    --label params                               \
      <(aws cloudformation describe-stacks       \
          --query "Stacks[].Parameters[]"        \
          --stack-name $stack                    |
        jq --sort-keys 'sort_by(.ParameterKey)') \
    --label $params                              \
      <(jq --sort-keys 'sort_by(.ParameterKey)' $params)

  if test $status -eq 0
    echo "params for stack ($stack) and contents of file ($params) are the same" >&2
  end
end

function _stack_name_arg
  # Extract the stack name from the template file
  # Allows us to specify template name as stack name
  # File extension gets stripped off
  basename "$argv[1]" | sed 's/\.[^.]*$//' # remove file extension
end

function _stack_template_arg -a _ arg2
  # Determine name of template to use
  set -l stack (_stack_name_arg $argv)
  set -q $arg2[1]
  or set -l template $arg2
  set -l stack_without_last (echo $stack | rev | cut -d- -f2- | rev)
  if test -z "$template"
    if test -f "$stack.json"
      set template "$stack.json"
    else if test -f "$stack_without_last.json"
      set template "$stack_without_last.json"
    end
  end
  echo $template
end

function stack-events
  # type: detail
  # return the events a stack has experienced
  set inputs (__fma_read_inputs $argv)
  set stack (_stack_name_arg $inputs)
  test -z "$stack"; and __fma_usage "stack"; and return 1

  if set output (aws cloudformation describe-stack-events \
                     --stack-name $stack                  \
                     --query "
                       sort_by(StackEvents, &Timestamp)[].[
                         Timestamp,
                         LogicalResourceId,
                         ResourceType,
                         ResourceStatus
                       ]"                                   \
                     --output table)
    echo \n$output | uniq -u
  else
    return $status
  end
end

function _stack_params_arg -a _ _ arg3
  # determine name of params file to use
  set stack (_stack_name_arg $argv)
  set template (_stack_template_arg $argv)
  if test -n "$arg3"
    set params $arg3
  else
    set params (echo $stack | sed "s/\("(basename $template .json)"\)\(.*\)/\1-params\2.json/")
  end
  if test -f "$params"
    echo $params
  end
end
