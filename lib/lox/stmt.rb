module Lox

  module Stmt
    Block = Data.define(:statements)
    Expression = Data.define(:expression)
    Print = Data.define(:expression)
    Var = Data.define(:name , :initializer)
  end
end