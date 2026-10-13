module Lox
  # Parser de descida recursiva para expressões da Lox.
  #
  # Gramática (da menor precedência para a maior):
  #
  #   expression → equality
  #   equality   → comparison ( ( "!=" | "==" ) comparison )*
  #   comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )*
  #   term       → factor ( ( "-" | "+" ) factor )*
  #   factor     → unary ( ( "/" | "*" ) unary )*
  #   unary      → ( "!" | "-" ) unary | primary
  #   primary    → NUMBER | STRING | "true" | "false" | "nil" | "(" expression ")"
  class Parser
    class ParseError < StandardError
      attr_reader :token

      def initialize(token, message)
        super(message)
        @token = token
      end
    end

    attr_reader :errors

    def initialize(tokens)
      @tokens = tokens
      @current = 0
      @errors = []
    end

    # Devolve a AST, ou nil se houve erro (os erros ficam em #errors).
    def parse
      expr = expression
      raise error(peek, "Esperava o fim da expressão.") unless at_end?

      expr
    rescue ParseError
      nil
    end

    private

    def expression = equality

    def equality   = left_associative(:comparison, :bang_equal, :equal_equal)

    def comparison = left_associative(:term, :greater, :greater_equal, :less, :less_equal)

    def term       = left_associative(:factor, :minus, :plus)

    def factor     = left_associative(:unary, :slash, :star)

    # Serve para todos os níveis binários: lê um operando, e enquanto
    # aparecer um dos operadores, lê outro operando e embrulha tudo num Binary.
    def left_associative(operand, *operators)
      expr = send(operand)

      while match(*operators)
        operator = previous
        right = send(operand)
        expr = Expr::Binary.new(left: expr, operator:, right:)
      end

      expr
    end

    def unary
      if match(:bang, :minus)
        operator = previous
        right = unary
        return Expr::Unary.new(operator:, right:)
      end

      primary
    end

    def primary
      return Expr::Literal.new(value: false) if match(:false)
      return Expr::Literal.new(value: true) if match(:true)
      return Expr::Literal.new(value: nil) if match(:nil)
      return Expr::Literal.new(value: previous.literal) if match(:number, :string)

      if match(:left_paren)
        expr = expression
        consume(:right_paren, "Esperava ')' depois da expressão.")
        return Expr::Grouping.new(expression: expr)
      end

      raise error(peek, "Esperava uma expressão.")
    end

    # --- auxiliares ---

    def match(*types)
      return false unless types.any? { |type| check(type) }

      advance
      true
    end

    def consume(type, message)
      return advance if check(type)

      raise error(peek, message)
    end

    def check(type) = !at_end? && peek.type == type

    def advance
      @current += 1 unless at_end?
      previous
    end

    def at_end? = peek.type == :eof

    def peek = @tokens[@current]

    def previous = @tokens[@current - 1]

    def error(token, message)
      where = token.type == :eof ? "no fim" : "em '#{token.lexeme}'"
      @errors << { line: token.line, message: "Erro #{where}: #{message}" }
      ParseError.new(token, message)
    end
  end
end