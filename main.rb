require 'open-uri'
require 'yaml'

def r
  load './main.rb'
end

# Load URL, Turn contents into an Array, Filter it, Pick one
def pick_word(min, max)
  url = 'https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt'
  words = URI.open(url).read.split
  valid_words = words.select { |word| word.length.between?(min, max) }
  secret_word = valid_words.sample
end

def get_input(guessed_letters)
  loop do
    print "Guess a letter (a-z) or type ':save', or type ':load': "
    input = gets.chomp.downcase

    return :save if input == ':save'
    return :load if input == ':load'

    if input !~ /\A[a-z]+\z/
      puts 'Only letters a-z are allowed.'
      next
    end

    if (input.length == 1) && guessed_letters.include?(input)
      puts 'You already guessed that letter.'
      next
    end
    return input
  end
end

def display_word(secret_word, guessed_letters)
  display = secret_word.chars.map do |letter|
    guessed_letters.include?(letter) ? letter : '_'
  end

  puts display.join(' ')
  display
end

def save_game(game_state)
  Dir.mkdir('saves') unless Dir.exist?('saves')

  print 'Enter a save name: '
  filename = gets.chomp

  File.open("saves/#{filename}.yml", 'w') do |file|
    file.write(game_state.to_yaml)
  end

  puts 'Game saved!'
end

def load_game
  unless Dir.exist?('saves')
    puts 'No saved games found.'
    return nil
  end

  saves = Dir.children('saves')
  if saves.empty?
    puts 'No saved games found.'
    return nil
  end

  puts 'Available saves:'
  saves.each_with_index do |file, index|
    puts "#{index + 1}: #{file}"
  end

  print 'Choose a save number: '
  choice = gets.chomp.to_i - 1

  return nil unless saves[choice]

  YAML.load_file("saves/#{saves[choice]}")
end

def play_round(min_length, max_length, rounds)
  rounds_left = rounds
  guessed_letters = []
  secret_word = pick_word(min_length, max_length)
  puts secret_word

  while rounds_left > 0
    input = get_input(guessed_letters)

    # Save
    if input == :save
      game_state = {
        secret_word: secret_word,
        guessed_letters: guessed_letters,
        rounds_left: rounds_left
      }
      save_game(game_state)
      puts 'Saving & Exiting game.'
      return
    end

    # Load
    if input == :load
      state = load_game
      if state
        secret_word = state[:secret_word]
        guessed_letters = state[:guessed_letters]
        rounds_left = state[:rounds_left]
        puts 'Game loaded!'
        puts rounds_left
        puts guessed_letters
        display = display_word(secret_word, guessed_letters)
        next
      end
    end

    # Tried Guessing a Word
    if input.length > 1
      if input == secret_word
        puts '🎉 Winner! You guessed the word!'
        return
      else
        puts 'Wrong word!'
        rounds_left -= 1
        next
      end
    end

    # Else: Proceed normally
    guessed_letters << input

    display = display_word(secret_word, guessed_letters)
    puts "Guessed letters: #{guessed_letters.join(', ')}"
    puts "Rounds left: #{rounds_left}"

    unless display.include?('_')
      puts '🎉 Winner!'
      return
    end
    rounds_left -= 1
  end

  puts 'Loss!'
  puts "The word was: #{secret_word}"
end

# Play Round(Min_Word_Length, Max_Word_Length, Round_Count)
play_round(4, 10, 3)
