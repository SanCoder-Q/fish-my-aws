#!/usr/local/bin/fish

set SOURCE_DIR (dirname (status -f))
set ROOT_DIR $SOURCE_DIR/..

function before
end

function after
end

function suite_stack_name_arg
  function test_without_an_argument
    assert_empty (_stack_name_arg)
  end

  function test_with_a_string
    assert_equal "argument" (_stack_name_arg "argument")
  end

  function test_with_a_file_extension
    assert_equal "file" (_stack_name_arg "file.json")
  end

  function test_with_a_full_json_path
    assert_equal "file" (_stack_name_arg "/path/to/file.json")
  end

  function test_with_a_yaml_file
    assert_equal "file" (_stack_name_arg "file.yaml")
  end

  function test_with_a_yml_file
    assert_equal "file" (_stack_name_arg "file.yml")
  end

  function test_with_a_full_yaml_path
    assert_equal "file" (_stack_name_arg "/path/to/file.yaml")
  end

  function test_with_a_full_xml_path
    assert_equal "file" (_stack_name_arg "/path/to/file.xml")
  end
end

function suite_stack_template_arg
  function test_cannot_find_template_without_any_details
    assert_equal "" (_stack_template_arg)
  end

  function test_cannot_find_template_with_only_stack_name
    assert_equal "" (_stack_template_arg "stack")
  end

  function test_cannot_find_template_when_it_s_gone
    assert_equal "/file/is/gone" (_stack_template_arg "stack" /file/is/gone)
  end

  function test_can_find_template_when_it_exists
    cd $TMPDIR
    touch stack.json
    assert_equal "stack.json" (_stack_template_arg "stack")
    rm stack.json
  end

  function test_can_find_template_when_stack_is_hyphenated_and_it_exists
    cd $TMPDIR
    touch stack.json
    assert_equal "stack.json" (_stack_template_arg "stack-example")
    rm stack.json
  end

  function test_can_find_template_when_it_is_provided
    set -l tmpfile (mktemp -t bma.XXX)
    assert_equal "$tmpfile" (_stack_template_arg "stack" "$tmpfile")
    rm $tmpfile
  end
end

if not set -q tank_running
  source $ROOT_DIR/test/helper.fish
  before
  tank_run
  after
end
