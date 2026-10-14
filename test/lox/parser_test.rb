require "test_helper"

class ParserTest < Minitest::Test
  def parse(source)
    tokens = Lox::Scanner.new(source).scan_tokens
    parser = Lox::Parser.new(tokens)
    [parser.parse_expression, parser.errors]
  end

  def ast(source)
    expr, _errors = parse(source)
    Lox::AstPrinter.new.render(expr)
  end

  def test_literals
    assert_equal "123.0", ast("123")
    assert_equal "oi", ast('"oi"')
    assert_equal "true", ast("true")
    assert_equal "false", ast("false")
    assert_equal "nil", ast("nil")
  end

  def test_multiplication_binds_tighter_than_addition
    assert_equal "(+ 1.0 (* 2.0 3.0))", ast("1 + 2 * 3")
  end

  def test_parentheses_override_precedence
    assert_equal "(* (group (+ 1.0 2.0)) 3.0)", ast("(1 + 2) * 3")
  end

  def test_subtraction_is_left_associative
    assert_equal "(- (- 1.0 2.0) 3.0)", ast("1 - 2 - 3")
  end

  def test_division_and_multiplication_group_from_the_left
    assert_equal "(* (/ 4.0 2.0) 3.0)", ast("4 / 2 * 3")
  end

  def test_unary_binds_tighter_than_binary
    assert_equal "(+ (- 1.0) 2.0)", ast("-1 + 2")
  end

  def test_unary_can_be_nested
    assert_equal "(! (! true))", ast("!!true")
  end

  def test_comparison_binds_tighter_than_equality
    assert_equal "(== (< 1.0 2.0) true)", ast("1 < 2 == true")
  end

  def test_book_example
    assert_equal "(* (- 123.0) (group 45.67))", ast("-123 * (45.67)")
  end

  def test_builds_binary_node_with_operator_token
    expr, errors = parse("1 + 2")

    assert_empty errors
    assert_instance_of Lox::Expr::Binary, expr
    assert_equal :plus, expr.operator.type
    assert_equal 1.0, expr.left.value
  end

  def test_missing_closing_parenthesis
    expr, errors = parse("(1 + 2")

    assert_nil expr
    assert_equal 1, errors.size
    assert_includes errors.first[:message], "Esperava ')'"
    assert_includes errors.first[:message], "no fim"
  end

  def test_missing_operand
    expr, errors = parse("1 +")

    assert_nil expr
    assert_includes errors.first[:message], "Esperava uma expressão."
  end

  def test_leftover_tokens_are_an_error
    expr, errors = parse("1 2")

    assert_nil expr
    assert_includes errors.first[:message], "em '2'"
    assert_includes errors.first[:message], "Esperava o fim da expressão."
  end

  def test_error_reports_line_number
    _expr, errors = parse("1 +\n\n*")

    assert_equal 3, errors.first[:line]
  end
end