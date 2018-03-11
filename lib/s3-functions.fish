#!/usr/local/bin/fish
#
# s3-functions

function buckets
  aws s3api list-buckets                      \
    --query "Buckets[].[Name, CreationDate]"  \
    --output text                            |\
    column -t
end

function bucket-acls
  set -l buckets (__fma_read_inputs $argv)
  test -z "$buckets"; and __fma_usage "bucket [bucket]"; and return 1

  set -l bucket
  for bucket in $buckets
    aws s3api get-bucket-acl \
      --bucket "$bucket"     \
      --query "[
         '$bucket',
         join(' ', Grants[?Grantee.Type=='Group'].[join('=',[Permission, Grantee.URI])][])
      ]"                     \
      --output text         |\
      sed 's#http://acs.amazonaws.com/groups/##g'
  end
end
