module Lox
  Token = Data.define(:type, :lexeme, :literal, :line) do
    def to_s
      "#{type} #{lexeme.inspect} #{literal.inspect}"
    end
  end
end