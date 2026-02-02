require 'open-uri'
require 'yaml'

def oop
  load './oop.rb'
end

class Hangman
  attr_accessor :secret_word, :guessed_letters, :rounds_left

  def initialize(min_length, max_length, rounds)
    @secret_word = pick_word(min_length, max_length)
    @guessed_letters = []
    @rounds_left = rounds
  end

  def pick_word(min, max)
    url = 'https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt'
    words = URI.open(url).read.split
    valid_words = words.select { |word| word.length.between?(min, max) }
    valid_words.sample
  end

  def get_input
    loop do
      print "Guess a letter (a-z), a word, or type ':save' / ':load': "
      input = gets.chomp.downcase

      return :save if input == ':save'
      return :load if input == ':load'

      if input !~ /\A[a-z]+\z/
        puts 'Only letters a-z are allowed.'
        next
      end

      if (input.length == 1) && @guessed_letters.include?(input)
        puts 'You already guessed that letter.'
        next
      end

      return input
    end
  end

  def display_word
    display = @secret_word.chars.map do |letter|
      @guessed_letters.include?(letter) ? letter : '_'
    end
    puts display.join(' ')
    display
  end

  def save_game
    Dir.mkdir('saves') unless Dir.exist?('saves')

    print 'Enter a save name: '
    filename = gets.chomp

    File.open("saves/#{filename}.yml", 'w') do |file|
      file.write(to_yaml) # serialize the whole object
    end

    puts 'Game saved!'
  end

  def self.load_game
    unless Dir.exist?('saves') && !Dir.children('saves').empty?
      puts 'No saved games found.'
      return nil
    end

    saves = Dir.children('saves')
    puts 'Available saves:'
    saves.each_with_index { |f, i| puts "#{i + 1}: #{f}" }

    print 'Choose a save number: '
    choice = gets.chomp.to_i - 1
    return nil unless saves[choice]

    YAML.load_file("saves/#{saves[choice]}")
  end

  def play
    while @rounds_left > 0
      input = get_input

      # Save
      if input == :save
        save_game
        puts 'Saving & Exiting game.'
        return
      end

      # Load
      if input == :load
        loaded = Hangman.load_game
        if loaded
          @secret_word = loaded.secret_word
          @guessed_letters = loaded.guessed_letters
          @rounds_left = loaded.rounds_left
          puts 'Game loaded!'
          display_word
        end
        next
      end

      # Word guess
      if input.length > 1
        if input == @secret_word
          puts '🎉 Winner! You guessed the word!'
          return
        else
          puts 'Wrong word!'
          @rounds_left -= 1
          next
        end
      end

      # Letter guess
      @guessed_letters << input
      display = display_word
      puts "Guessed letters: #{@guessed_letters.join(', ')}"
      puts "Rounds left: #{@rounds_left}"

      unless display.include?('_')
        puts '🎉 Winner!'
        return
      end

      @rounds_left -= 1
    end

    puts "Loss! The word was: #{@secret_word}"
  end
end

# Either start new game:
game = Hangman.new(4, 10, 5)
game.play

# Or load an existing one:
# game = Hangman.load_game
# game.play if gamer
