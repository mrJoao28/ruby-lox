module Lox
  # Interpretador "tree-walking": percorre a AST e calcula o resultado.
  #
  # Valores da Lox são representados por tipos do próprio Ruby:
  #   número => Float | string => String | booleano => true/false | nil => nil
  class Interpreter
    class LoxRuntimeError < StandardError
      attr_reader :token

      def initialize(token, message)
        super(message)
        @token = token
      end
    end

    attr_reader :errors

    def initialize
      @errors = []
    end

    # Avalia a expressão e devolve o resultado como texto (ou nil se houve
    # erro de execução, que fica registrado em #errors).
    def interpret(expr)
      stringify(evaluate(expr))
    rescue LoxRuntimeError => e
      @errors << { line: e.token.line, message: "Erro de execução: #{e.message}" }
      nil
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
      end
    end

    private

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