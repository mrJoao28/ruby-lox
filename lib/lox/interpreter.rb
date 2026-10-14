module Lox
  # Interpretador "tree-walking": percorre a AST e executa o programa.
  #
  # Valores da Lox são representados por tipos do próprio Ruby:
  #   número => Float | string => String | booleano => true/false | nil => nil
  class Interpreter
    attr_reader :errors

    # `output` é para onde o `print` escreve (nos testes, um StringIO).
    def initialize(output: $stdout)
      @output = output
      @environment = Environment.new # escopo global
      @errors = []
    end

    # Executa as instruções. Devolve true se tudo deu certo, false se houve
    # erro de execução (que fica registrado em #errors).
    def interpret(statements)
      @errors = []
      statements.each { |statement| execute(statement) }
      true
    rescue LoxRuntimeError => e
      @errors << { line: e.token.line, message: "Erro de execução: #{e.message}" }
      false
    end

    def evaluate(expr)
      case expr
      in Expr::Literal(value:)
        value
      in Expr::Grouping(expression:)
        evaluate(expression)
      in Expr::Unary(operator:, right:)
        evaluate_unary(operator, evaluate(right))
      in Expr::Binary(left:, operator:, right:)
        evaluate_binary(operator, evaluate(left), evaluate(right))
      in Expr::Variable(name:)
        @environment.get(name)
      in Expr::Assign(name:, value:)
        result = evaluate(value)
        @environment.assign(name, result)
        result
      end
    end

    private

    # --- instruções ---

    def execute(statement)
      case statement
      in Stmt::Expression(expression:)
        evaluate(expression)
      in Stmt::Print(expression:)
        @output.puts(stringify(evaluate(expression)))
      in Stmt::Var(name:, initializer:)
        value = initializer.nil? ? nil : evaluate(initializer)
        @environment.define(name.lexeme, value)
      in Stmt::Block(statements:)
        execute_block(statements, Environment.new(@environment))
      end

      nil
    end

    # Executa as instruções num escopo novo e SEMPRE volta ao escopo anterior,
    # mesmo que aconteça um erro no meio do bloco.
    def execute_block(statements, environment)
      previous = @environment
      @environment = environment
      statements.each { |statement| execute(statement) }
    ensure
      @environment = previous
    end

    # --- expressões ---

    def evaluate_unary(operator, right)
      case operator.type
      when :minus
        check_numbers!(operator, right)
        -right
      when :bang
        !truthy?(right)
      end
    end

    def evaluate_binary(operator, left, right)
      case operator.type
      when :plus
        return left + right if numbers?(left, right) || strings?(left, right)

        raise LoxRuntimeError.new(operator, "Os operandos devem ser dois números ou duas strings.")
      when :minus
        check_numbers!(operator, left, right)
        left - right
      when :star
        check_numbers!(operator, left, right)
        left * right
      when :slash
        check_numbers!(operator, left, right)
        left / right
      when :greater
        check_numbers!(operator, left, right)
        left > right
      when :greater_equal
        check_numbers!(operator, left, right)
        left >= right
      when :less
        check_numbers!(operator, left, right)
        left < right
      when :less_equal
        check_numbers!(operator, left, right)
        left <= right
      when :equal_equal
        left == right
      when :bang_equal
        left != right
      end
    end

    # Na Lox, só `nil` e `false` são falsos. Tudo mais (inclusive 0 e "") é verdadeiro.
    def truthy?(value) = !(value.nil? || value == false)

    def numbers?(*values) = values.all?(Float)

    def strings?(*values) = values.all?(String)

    def check_numbers!(operator, *operands)
      return if numbers?(*operands)

      message = operands.size == 1 ? "O operando deve ser um número." : "Os operandos devem ser números."
      raise LoxRuntimeError.new(operator, message)
    end

    def stringify(value)
      case value
      when nil
        "nil"
      when Float
        text = value.to_s
        text.end_with?(".0") ? text.delete_suffix(".0") : text
      else
        value.to_s
      end
    end
  end
end