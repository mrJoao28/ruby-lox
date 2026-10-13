module Lox
  module Expr
    Binary = Data.define(:left , :operator, :right)
    Grouping = Data.define(:expression)
    Literal = Data.define(:value)
    Unary = Data.define(:operator , :right)
  end
end