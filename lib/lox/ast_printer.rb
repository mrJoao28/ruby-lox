module Lox

  class AstPrinter
    def render(expr)
      case expr
      in Expr::Binary(left:, operator:, right:)
        parenthesize(operator.lexeme, left, right)
      in Expr::Grouping(expression:)
        parenthesize("group" , expression)
      in Expr::Literal(value:)
        value.nil? ? "nil": value.to_s
      in Expr::Unary(operator:, right:)
        parenthesize(operator.lexeme, right)
      end
    end
  private

  def parenthesize(name, *exprs)
    "(#{name} #{exprs.map {|expr| render(expr)}.join(' ')})"
  end
end
end