require "rubygems"
require "ffi/aspell"

module Phone2Word
  class Combinations
    def initialize(sets)
      @sets = sets
    end

    def each(ls=[], &block)
      if ls.size == @sets.size
        block.call(ls)
      else
        @sets[ls.size].each do |l|
          each(ls + [l], &block)
        end
      end
    end
  end

  class Number
    MAP = {
      0 => %w(),
      1 => %w(),
      2 => %w(A Ā B C Č),
      3 => %w(D E Ē F),
      4 => %w(G Ģ H I Ī),
      5 => %w(J K Ķ L Ļ),
      6 => %w(M N Ņ O),
      7 => %w(P Q R S Š),
      8 => %w(T U Ū V),
      9 => %w(W X Y Z Ž)
    }

    attr_reader :number

    def initialize(number)
      @number = number.each_char.map(&:to_i).to_a
    end

    def letters
      @number.map { |n| MAP[n] }
    end

    def letter_combinations
      Combinations.new(letters)
    end

    def words(lang = "en", &block)
      speller = FFI::Aspell::Speller.new(lang)
      letter_combinations.each do |combination|
        word = combination.join
        if speller.correct?(word.downcase)
          block.call(word)
        end
      end
    ensure
      speller.close
    end

    def split(number = @number, first=true)
      yield [Number.new(number.join)] if first
      (number.size-3).times do |i|
        parts = number[0..i+1], number[i+2..-1]
        yield parts.map { |p| Number.new(p.join) }
        split(parts[1], false) do |sparts|
          yield [Number.new(parts[0].join)] + sparts
        end
      end
    end

    def each(&block)
      split do |parts|
        part_words = parts.map do |part|
          words = []
          part.words(ARGV[1]) do |word|
            words << word
          end
          words << part.number.join if words.empty?
          words
        end
        Combinations.new(part_words).each(&block)
      end
    end
  end
end

number = Phone2Word::Number.new(ARGV[0])
number.each do |parts|
  next if parts.join =~ /^[0-9]+$/
  puts parts.join("-")
end
