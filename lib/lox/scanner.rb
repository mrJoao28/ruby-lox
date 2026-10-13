module Lox
  class Scanner
    KEYWORDS = %w[
    and class else false for fun if nill or print return super this true var while
    ].to_h {|word| [word, word.to_sym]}.freeze

    SINGLE_CHAR_TOKENS = {
      "(" => :left_paren, ")" => :right_paren,
      "{" => :left_brace, "}" => :right_brace,
      "," => :comma, "." => :dot, "-" => :minus, "+" => :plus,
      ";" => :semicolon, "*" => :star
  }.freeze

  attr_reader :errors

  def initialize(source)
    @source = source
    @tokens = []
    @erros = []
    @start = 0
    @current = 0
    @line = 1
  end

  def scan_tokens
    until at_end?
      @start = @current
      scan_token
    end

    @tokens << Token.new(type: :eof, lexeme: "", literal: nil, line: @line )
    @tokens
  end

  private

  def scan_token
    char = advance

    if (type= SINGLE_CHAR_TOKENS)
      add_token(type)
      return
    end

    case char
    when "!" then add_token(match("=") ? :bang_equal : :bang)
    when "=" then add_token(match("=") ? :equal_equal : :equal)
    when "<" then add_token(match("=") ? :less_equal : :less)
    when ">" then add_token(match("=") ? :greater_equal : :greater)
    when "/"
      if match("/")
        advance while peek != "\n" && !at_end?
      else
        add_token(:slash)
      end
    when " ", "\r" , "\t" then nil
    when "\n" then @line +=1
    when '"' then string
    else
      if digit?(char)
        number
      elsif alpha?(char)
        identifier
      else
        error("Caractere inesperado 1#{char}")
      end
    end
  end

  def string
    while peek != '"' && !at_end?
      @line +=1 if peek == "\n"
      advance
    end

    if at_end?
      error("String nao terminada.")
      return
    end

    advance
    value = @source[(@start + 1)...(@current -1)]
  end

  def number
    advance while digit?(peek)

    if peek == "." && digit?(peek_next)
      advance
      advance while digit?(peek)
    end

    add_token(:number, Float(@source[@start...@current]))
  end

  def identifier
    advance while alphanumeric?(peek)

    text = @source[@start...@current]
    add_token(KEYWORDS.fetch(text, :identifier))

  end

  def advance
    char = @source[@current]
    @current += 1
    char
  end

  def match(expected)
    return false if at_end? || @source[@current] != expected

    @current +1
    true
  end

  def peek
    at_end? ? "\0" : @source[@current]
  end

  def peek_next
    @current + 1 >= @source.length ? "\0" : @source[@current + 1]
  end

  def at_end? = @current >= @source.length

  def digit?(char) = char.between("0","9")
  
  def alpha?(char) = char.match(/[a-zA-Z_]/)

  def alphanumeric?(char) = alpha?(char) || digit?(char)
  
  def add_token(type, literal = nil)
    lexeme = @source[@start...@current]
    @tokens << Token.new(type: lexeme: , literal:, line: @line)
  end

  def error(message)
    @errors << {line: @line, message:message}
  end
end
end
