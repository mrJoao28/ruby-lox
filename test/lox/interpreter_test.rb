require "test_helper"
require "stringio"

class InterpreterTest < Minitest::Test
  def parse(source)
    tokens = Lox::Scanner.new(source).scan_tokens
    Lox::Parser.new(tokens).parse_expression
  end

  # Devolve o valor Ruby da expressão.
  def evaluate(source)
    Lox::Interpreter.new.evaluate(parse(source))
  end

  # Devolve [texto, erros], como o executável faz.
  def interpret(source)
    out = StringIO.new
    interpreter = Lox::Interpreter.new(output: out)
    ok = interpreter.interpret([Lox::Stmt::Print.new(expression: parse(source))])
    [ok ? out.string.chomp : nil, interpreter.errors]
  end

  def test_arithmetic_respects_precedence
    assert_equal 7.0, evaluate("1 + 2 * 3")
    assert_equal 9.0, evaluate("(1 + 2) * 3")
  end

  def test_subtraction_and_division_are_left_associative
    assert_equal(-4.0, evaluate("1 - 2 - 3"))
    assert_equal 6.0, evaluate("12 / 2 / 1")
    assert_equal 6.0, evaluate("4 / 2 * 3")
  end

  def test_unary_minus
    assert_equal(-3.0, evaluate("-3"))
    assert_equal 3.0, evaluate("--3")
    assert_equal 1.0, evaluate("-1 + 2")
  end

  def test_string_concatenation
    assert_equal "olá, Lox", evaluate('"olá, " + "Lox"')
  end

  def test_comparisons
    assert_equal true,  evaluate("1 < 2")
    assert_equal true,  evaluate("2 <= 2")
    assert_equal false, evaluate("3 > 4")
    assert_equal true,  evaluate("5 >= 5")
  end

  def test_equality_works_across_types_without_errors
    assert_equal true,  evaluate("nil == nil")
    assert_equal false, evaluate('1 == "1"')
    assert_equal true,  evaluate('"a" == "a"')
    assert_equal true,  evaluate("true != false")
    assert_equal false, evaluate("nil == false")
  end

  def test_only_nil_and_false_are_falsy
    assert_equal true,  evaluate("!nil")
    assert_equal true,  evaluate("!false")
    assert_equal false, evaluate("!0")
    assert_equal false, evaluate('!""')
    assert_equal true,  evaluate('!!"x"')
  end

  def test_numbers_are_printed_without_trailing_zero
    assert_equal "7", interpret("1 + 2 * 3").first
    assert_equal "2.5", interpret("10 / 4").first
    assert_equal "-4", interpret("1 - 2 - 3").first
  end

  def test_other_values_are_printed
    assert_equal "nil", interpret("nil").first
    assert_equal "true", interpret("1 < 2").first
    assert_equal "oi", interpret('"oi"').first
  end

  def test_division_by_zero_follows_floating_point_rules
    assert_equal "Infinity", interpret("1 / 0").first
    assert_equal "-Infinity", interpret("-1 / 0").first
  end

  def test_negating_a_non_number_is_a_runtime_error
    output, errors = interpret('-"a"')

    assert_nil output
    assert_equal 1, errors.size
    assert_includes errors.first[:message], "O operando deve ser um número."
  end

  def test_arithmetic_on_wrong_types_is_a_runtime_error
    ['"a" - 1', "1 * nil", "true / 2", '1 < "a"'].each do |source|
      output, errors = interpret(source)

      assert_nil output, "esperava erro em #{source}"
      assert_includes errors.first[:message], "Os operandos devem ser números.", source
    end
  end

  def test_plus_requires_two_numbers_or_two_strings
    output, errors = interpret('1 + "a"')

    assert_nil output
    assert_includes errors.first[:message], "dois números ou duas strings"
  end

  def test_runtime_error_reports_operator_line
    _output, errors = interpret("\n\n1 + \"a\"")

    assert_equal 3, errors.first[:line]
  end
end