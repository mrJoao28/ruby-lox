require "test_helper"
require "stringio"

class ProgramTest < Minitest::Test
  def setup
    @out = StringIO.new
    @interpreter = Lox::Interpreter.new(output: @out)
  end

  # Executa o código no mesmo interpretador (como o REPL faz) e devolve true/false.
  def run_code(source)
    tokens = Lox::Scanner.new(source).scan_tokens
    parser = Lox::Parser.new(tokens)
    statements = parser.parse
    assert_empty parser.errors, "erro de sintaxe inesperado em: #{source}"
    @interpreter.interpret(statements)
  end

  def output = @out.string

  def error_message = @interpreter.errors.first[:message]

  def test_print
    run_code("print 1 + 2;")
    assert_equal "3\n", output
  end

  def test_print_formats_values
    run_code('print 7 / 2; print "a" + "b"; print nil; print 1 < 2;')
    assert_equal "3.5\nab\nnil\ntrue\n", output
  end

  def test_expression_statement_prints_nothing
    run_code("1 + 2;")
    assert_equal "", output
  end

  def test_variables
    run_code("var a = 1; var b = 2; print a + b;")
    assert_equal "3\n", output
  end

  def test_uninitialized_variable_is_nil
    run_code("var a; print a;")
    assert_equal "nil\n", output
  end

  def test_assignment_changes_the_value
    run_code("var a = 1; a = 2; print a;")
    assert_equal "2\n", output
  end

  def test_assignment_is_an_expression_with_a_value
    run_code("var a; var b; a = b = 3; print a + b;")
    assert_equal "6\n", output
  end

  def test_global_variables_can_be_redefined
    run_code("var a = 1; var a = 2; print a;")
    assert_equal "2\n", output
  end

  def test_reading_an_undefined_variable_is_a_runtime_error
    assert_equal false, run_code("print x;")
    assert_includes error_message, "Variável 'x' não definida."
    assert_equal "", output
  end

  def test_assigning_to_an_undefined_variable_is_a_runtime_error
    assert_equal false, run_code("x = 1;")
    assert_includes error_message, "Variável 'x' não definida."
  end

  def test_inner_scope_shadows_outer_scope
    run_code('var a = "fora"; { var a = "dentro"; print a; } print a;')
    assert_equal "dentro\nfora\n", output
  end

  def test_inner_scope_can_read_outer_variables
    run_code("var a = 1; { var b = a + 1; print b; }")
    assert_equal "2\n", output
  end

  def test_inner_scope_can_assign_outer_variables
    run_code("var a = 1; { a = 2; } print a;")
    assert_equal "2\n", output
  end

  def test_block_variables_do_not_leak
    assert_equal false, run_code("{ var a = 1; } print a;")
    assert_includes error_message, "Variável 'a' não definida."
  end

  def test_scope_is_restored_after_a_runtime_error
    assert_equal false, run_code("{ var a = 1; print x; }")
    assert_equal false, run_code("print a;")

    assert_includes error_message, "Variável 'a' não definida."
  end

  def test_state_persists_between_runs_like_a_repl
    run_code("var a = 1;")
    run_code("print a + 1;")

    assert_equal "2\n", output
  end

  def test_statements_before_an_error_still_run
    assert_equal false, run_code("print 1; print x; print 2;")
    assert_equal "1\n", output
  end

  def test_runtime_error_reports_line
    run_code("var a = 1;\nprint a + \"x\";")

    assert_equal 2, @interpreter.errors.first[:line]
  end
end