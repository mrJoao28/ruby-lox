require "test_helper"

class ParserStatementsTest < Minitest::Test
  def parse_program(source)
    tokens = Lox::Scanner.new(source).scan_tokens
    parser = Lox::Parser.new(tokens)
    [parser.parse, parser.errors]
  end

  def ast(source)
    statements, errors = parse_program(source)
    assert_empty errors
    printer = Lox::AstPrinter.new
    statements.map { |statement| printer.render(statement) }
  end

  def test_print_statement
    assert_equal ["(print (+ 1.0 2.0))"], ast("print 1 + 2;")
  end

  def test_expression_statement
    assert_equal ["(expr (* 2.0 3.0))"], ast("2 * 3;")
  end

  def test_var_with_and_without_initializer
    assert_equal ["(var a 1.0)", "(var b)"], ast("var a = 1; var b;")
  end

  def test_assignment_is_an_expression
    assert_equal ["(expr (= a 1.0))"], ast("a = 1;")
  end

  def test_assignment_is_right_associative
    assert_equal ["(expr (= a (= b 2.0)))"], ast("a = b = 2;")
  end

  def test_variable_in_expression
    assert_equal ["(print (+ a 1.0))"], ast("print a + 1;")
  end

  def test_block
    assert_equal ["(block (var a 1.0) (print a))"], ast("{ var a = 1; print a; }")
  end

  def test_empty_block_and_nested_blocks
    assert_equal ["(block)", "(block (block))"], ast("{} { {} }")
  end

  def test_invalid_assignment_target
    ["1 = 2;", "a + b = c;"].each do |source|
      _statements, errors = parse_program(source)

      assert_equal 1, errors.size, source
      assert_includes errors.first[:message], "Alvo de atribuição inválido.", source
    end
  end

  def test_missing_semicolon
    _statements, errors = parse_program("print 1")

    assert_includes errors.first[:message], "Esperava ';'"
    assert_includes errors.first[:message], "no fim"
  end

  def test_missing_variable_name
    _statements, errors = parse_program("var = 1;")

    assert_includes errors.first[:message], "Esperava um nome de variável."
  end

  def test_unclosed_block
    _statements, errors = parse_program("{ print 1;")

    assert_includes errors.first[:message], "Esperava '}'"
  end

  def test_parser_recovers_and_reports_several_errors
    statements, errors = parse_program("var = 1;\nprint 2 +;\nprint 3;")

    assert_equal [1, 2], errors.map { |error| error[:line] }
    assert_equal 1, statements.size
    assert_equal "(print 3.0)", Lox::AstPrinter.new.render(statements.first)
  end
end