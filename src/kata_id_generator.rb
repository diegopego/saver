require_relative 'base58'

class KataIdGenerator

  def initialize(externals)
    @externals = externals
  end

  def id
    loop do
      id = Base58.string(6)
      unless katas.kata_exists?(id)
        return id
      end
    end
  end

  private

  def katas
    @externals.katas
  end

end