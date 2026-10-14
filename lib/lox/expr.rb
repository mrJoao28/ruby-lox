module Lox
  module Expr
    Assign = Data.define(:name , :value)
    Binary = Data.define(:left , :operator, :right)
    Grouping = Data.define(:expression)
    Literal = Data.define(:value)
    Unary = Data.define(:operator , :right)
    Variable = Data.define(:name)
  end
end