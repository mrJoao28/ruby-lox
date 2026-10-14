module Lox

  class LoxRuntimeError < StandardError
    attr_reader :token

    def initialize(token , message)
      super(message)
      @token = token
    end
  end
end
