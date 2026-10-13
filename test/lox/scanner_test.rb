require "test_helper"

class ScannerTest < Minitest::Test
  def scan(source)
    Lox::Scanner.new(source).scan_tokens
  end

  def types(source)
    scan(source).map(&:type)
  end

  def test_empty_source_yields_only_eof
    assert_equal [:eof], types("")
  end

  def test_single_character_tokens
    assert_equal %i[left_paren right_paren left_brace right_brace comma dot minus plus semicolon star eof],
                 types("(){},.-+;*")
  end

  def test_one_or_two_character_operators
    assert_equal %i[bang bang_equal equal equal_equal less less_equal greater greater_equal eof],
                 types("! != = == < <= > >=")
  end

  def test_slash_and_comments
    assert_equal %i[slash eof], types("/ // isto é um comentário")
  end

  def test_numbers
    tokens = scan("123 45.67")
    assert_equal [123.0, 45.67], tokens.first(2).map(&:literal)
  end

  def test_number_does_not_swallow_trailing_dot
    assert_equal %i[number dot eof], types("123.")
  end

  def test_strings
    token = scan('"olá, mundo"').first
    assert_equal :string, token.type
    assert_equal "olá, mundo", token.literal
  end

  def test_multiline_string_counts_lines
    tokens = scan(%("a\nb"\nx))
    assert_equal [2, 3, 3], tokens.map(&:line)
  end

  def test_keywords_and_identifiers
    assert_equal %i[var identifier equal number semicolon eof], types("var nome = 10;")
  end

  def test_identifier_that_starts_with_a_keyword
    assert_equal %i[identifier eof], types("orchid")
  end

  def test_unterminated_string_reports_error
    scanner = Lox::Scanner.new('"abc')
    scanner.scan_tokens

    assert_equal 1, scanner.errors.size
    assert_equal "String não terminada.", scanner.errors.first[:message]
  end

  def test_unexpected_character_reports_error_and_keeps_scanning
    scanner = Lox::Scanner.new("1 @ 2")
    tokens = scanner.scan_tokens

    assert_equal %i[number number eof], tokens.map(&:type)
    assert_equal 1, scanner.errors.size
  end
end