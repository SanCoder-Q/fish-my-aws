#!/usr/local/bin/fish

set SOURCE_DIR (dirname (status -f))
set ROOT_DIR $SOURCE_DIR/..

function before
end

function after
end

function suite_with_fma_usage
  function test_call_with_a_string
    assert_equal "USAGE:  something" (__fma_usage "something" 2>&1)
  end
end

function suite_with_fma_read_stdin

  function test_single_word_on_a_single_line
    assert_equal "a" (echo "a" | __fma_read_stdin)
  end

  function test_multi_word_on_a_single_line
    assert_equal "a" (echo "a blah" | __fma_read_stdin)
  end

  function test_single_word_on_multi_line
    assert_equal "a b" (printf "a\nb" | __fma_read_stdin)
  end

  function test_multi_word_on_a_multi_line
    assert_equal "a b" (printf "a blah\nb else\n" | __fma_read_stdin)
  end
end

function suite_fma_read_inputs
  function test_empty
    set val (__fma_read_stdin)
    assert_empty $val
  end

  function test_with_stdin
    set val (echo "a blah" | __fma_read_inputs)
    assert_equal "a" $val
  end

  function test_with_argv
    set val (__fma_read_inputs "argv")
    assert_equal "argv" $val
  end

  function test_multi_word_on_a_single_line
    set val (printf "a blah\nb else\n" | __fma_read_inputs)
    assert_equal "a b" $val
  end
end

if not set -q tank_running
  source $ROOT_DIR/test/helper.fish
  before
  tank_run
  after
end
