module Lox
  # Guarda as variáveis de um escopo. Cada escopo aponta para o escopo de fora,
  # formando uma cadeia que vai do escopo atual até o global.
  class Environment
    attr_reader :enclosing

    def initialize(enclosing = nil)
      @values = {}
      @enclosing = enclosing
    end

    # Cria (ou redefine) uma variável NESTE escopo.
    def define(name, value)
      @values[name] = value
    end

    def get(token)
      return @values[token.lexeme] if @values.key?(token.lexeme)
      return @enclosing.get(token) if @enclosing

      raise LoxRuntimeError.new(token, "Variável '#{token.lexeme}' não definida.")
    end

    # Altera uma variável que JÁ existe, no escopo mais próximo que a tenha.
    def assign(token, value)
      if @values.key?(token.lexeme)
        @values[token.lexeme] = value
      elsif @enclosing
        @enclosing.assign(token, value)
      else
        raise LoxRuntimeError.new(token, "Variável '#{token.lexeme}' não definida.")
      end
    end
  end
end