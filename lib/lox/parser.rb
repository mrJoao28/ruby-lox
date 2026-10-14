module Lox
  # Parser de descida recursiva da Lox.
  #
  # Gramática:
  #
  #   program     → declaration* EOF
  #   declaration → varDecl | statement
  #   varDecl     → "var" IDENTIFIER ( "=" expression )? ";"
  #   statement   → exprStmt | printStmt | block
  #   exprStmt    → expression ";"
  #   printStmt   → "print" expression ";"
  #   block       → "{" declaration* "}"
  #
  #   expression  → assignment
  #   assignment  → IDENTIFIER "=" assignment | equality
  #   equality    → comparison ( ( "!=" | "==" ) comparison )*
  #   comparison  → term ( ( ">" | ">=" | "<" | "<=" ) term )*
  #   term        → factor ( ( "-" | "+" ) factor )*
  #   factor      → unary ( ( "/" | "*" ) unary )*
  #   unary       → ( "!" | "-" ) unary | primary
  #   primary     → NUMBER | STRING | "true" | "false" | "nil" | IDENTIFIER | "(" expression ")"
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

    # Lê o programa inteiro e devolve a lista de instruções.
    # Se houver erros, eles ficam em #errors (e a lista só tem o que deu certo).
    def parse
      statements = []

      until at_end?
        statement = declaration
        statements << statement if statement
      end

      statements
    end

    # Lê UMA expressão (usado nos testes e no REPL). Devolve nil se houver erro.
    def parse_expression
      expr = expression
      raise error(peek, "Esperava o fim da expressão.") unless at_end?

      expr
    rescue ParseError
      nil
    end

    private

    # --- instruções ---

    def declaration
      return var_declaration if match(:var)

      statement
    rescue ParseError
      synchronize
      nil
    end

    def var_declaration
      name = consume(:identifier, "Esperava um nome de variável.")
      initializer = match(:equal) ? expression : nil
      consume(:semicolon, "Esperava ';' depois da declaração da variável.")

      Stmt::Var.new(name:, initializer:)
    end

    def statement
      return print_statement if match(:print)
      return Stmt::Block.new(statements: block) if match(:left_brace)

      expression_statement
    end

    def print_statement
      value = expression
      consume(:semicolon, "Esperava ';' depois do valor.")

      Stmt::Print.new(expression: value)
    end

    def expression_statement
      expr = expression
      consume(:semicolon, "Esperava ';' depois da expressão.")

      Stmt::Expression.new(expression: expr)
    end

    def block
      statements = []

      while !check(:right_brace) && !at_end?
        statement = declaration
        statements << statement if statement
      end

      consume(:right_brace, "Esperava '}' depois do bloco.")
      statements
    end

    # --- expressões ---

    def expression = assignment

    def assignment
      expr = equality

      if match(:equal)
        equals = previous
        value = assignment # recursão: a atribuição agrupa pela direita (a = b = c)

        return Expr::Assign.new(name: expr.name, value:) if expr.is_a?(Expr::Variable)

        # Só registra o erro: o parser não está "perdido", então não precisa levantar.
        error(equals, "Alvo de atribuição inválido.")
      end

      expr
    end

    def equality   = left_associative(:comparison, :bang_equal, :equal_equal)

    def comparison = left_associative(:term, :greater, :greater_equal, :less, :less_equal)

    def term       = left_associative(:factor, :minus, :plus)

    def factor     = left_associative(:unary, :slash, :star)

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
      return Expr::Variable.new(name: previous) if match(:identifier)

      if match(:left_paren)
        expr = expression
        consume(:right_paren, "Esperava ')' depois da expressão.")
        return Expr::Grouping.new(expression: expr)
      end

      raise error(peek, "Esperava uma expressão.")
    end

    # --- recuperação de erros ---

    # Depois de um erro, descarta tokens até chegar a um ponto seguro
    # (depois de um ';' ou antes de uma palavra que começa uma instrução).
    def synchronize
      advance

      until at_end?
        return if previous.type == :semicolon
        return if %i[class fun var for if while print return].include?(peek.type)

        advance
      end
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