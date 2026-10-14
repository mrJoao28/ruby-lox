module Lox
  # Mostra a árvore em notação de parênteses: 1 + 2 * 3  =>  (+ 1.0 (* 2.0 3.0))
  class AstPrinter
    def render(node)
      case node
      in Expr::Binary(left:, operator:, right:)
        wrap(operator.lexeme, render(left), render(right))
      in Expr::Grouping(expression:)
        wrap("group", render(expression))
      in Expr::Literal(value:)
        value.nil? ? "nil" : value.to_s
      in Expr::Unary(operator:, right:)
        wrap(operator.lexeme, render(right))
      in Expr::Variable(name:)
        name.lexeme
      in Expr::Assign(name:, value:)
        wrap("= #{name.lexeme}", render(value))
      in Stmt::Expression(expression:)
        wrap("expr", render(expression))
      in Stmt::Print(expression:)
        wrap("print", render(expression))
      in Stmt::Var(name:, initializer:)
        initializer ? wrap("var #{name.lexeme}", render(initializer)) : wrap("var #{name.lexeme}")
      in Stmt::Block(statements:)
        wrap("block", *statements.map { |statement| render(statement) })
      end
    end

    private

    def wrap(name, *parts)
      "(#{[name, *parts].join(' ')})"
    end
  end
end