#!/usr/local/bin/fish

set SOURCE_DIR (dirname (status -f))
set ROOT_DIR $SOURCE_DIR/..

__fma_complete_subcommand buckets 'list all s3 buckets'

__fma_complete_subcommand bucket-acls 'list buckets acl groups of a bucket'
