class ChordGenerator
  MIN_KEYS = 2.freeze
  MIN_CHARS = 2.freeze
  FILE_NAME = "words.txt".freeze
  KEY_MIRROR_MAP_L = {
    "," => ";",
    "u" => "s",
    "'" => "y",
    "." => "j",
    "o" => "n",
    "i" => "l",
    "e" => "t",
    "r" => "a",
    "v" => "p",
    "m" => "h",
    "c" => "d",
    "k" => "f",
    "z" => "q",
    "w" => "b",
    "g" => "Dup",
    "x" => nil
  }.freeze
  KEY_MIRROR_MAP_R = KEY_MIRROR_MAP_L.invert.freeze
  KEY_FINGER_MAP = {
     "LH_Ring_Primary" => %w(, u ' LH_Ring_Primary_Center),
     "LH_Middle_Primary" => %w(. o i LH_Middle_Primary_Center),
     "LH_Index" => %w(e r LH_Index_Center),
     "LH_Thumb_1" => %w(m v k c LH_Thumb_1_Center),
     "LH_Thumb_2" => %w(g z w LH_Thumb_2_Center),
     "RH_Thumb_2" => %w(x b q RH_Thumb_2_Center),
     "RH_Thumb_1" => %w(p f d h RH_Thumb_1_Center),
     "RH_Index" => %w(a t RH_Index_Center),
     "RH_Middle_Primary" => %w(l n j RH_Middle_Primary_Center),
     "RH_Ring_Primary" => %w(y s ; RH_Ring_Primary_Center)
  }.freeze

  def initialize
    @used_chords = {}
  end

  def generate
    sorted_words.each do |word|
      raise "Word is blank" if word.nil?

      next if word.length < MIN_CHARS

      uniq_chars = word.chars.uniq.join
      chord = less_keys_logic(uniq_chars) || more_keys_logic(uniq_chars) || mirror_keys_logic(uniq_chars) || three_d_keys_logic(uniq_chars)

      unless chord
        puts "Could not find chord for #{word}"
        next
      end

      assign_chord(word, chord)
      puts "#{word},#{chord.join(" + ")}"
    end
  end

  def assign_chord(word, chord)
    @used_chords[word] = chord.sort
  end

  def less_keys_logic(word)
    chord = []
    word.each_char.with_index do |char, index|
      chord << char
      next chord.pop if finger_conflict?(chord)
      next if (index + 1) < MIN_KEYS
      next chord.pop if already_used_chord?(chord)

      return chord
    end
    false
  end

  def more_keys_logic(word)
    chord = []
    word.each_char.with_index do |char, index|
      chord << char
      next chord.pop if finger_conflict?(chord)
      next if (index + 1) < MIN_KEYS
      next if already_used_chord?(chord)

      return chord
    end
    false
  end

  def mirror_keys_logic(word)
    chord = []
    word.each_char.with_index do |char, index|
      chord << char
      next if (index + 1) < MIN_KEYS

      mirror_key_combinations(chord).each do |mirror_chord|
        next if finger_conflict?(chord)
        next if already_used_chord?(mirror_chord)

        return mirror_chord
      end
    end
    false
  end

  def three_d_keys_logic(word)
    chord = []
    word.each_char.with_index do |char, index|
      chord << char
      next if (index + 1) < MIN_KEYS

      three_d_key_combinations(chord).each do |three_d_chord|
        next if finger_conflict?(chord)
        next if already_used_chord?(three_d_chord)

        return three_d_chord
      end
    end
    false
  end

  def finger_conflict?(chord)
    KEY_FINGER_MAP.values.any? do |finger_keys|
      (finger_keys & chord).size > 1
    end
  end

  def already_used_chord?(chord)
    return false if chord.nil?

    @used_chords.values.include?(chord.sort)
  end

  def mirror_key_combinations(chord)
    combinations = [[]]
    chord.each do |char|
      mirror_key = KEY_MIRROR_MAP_L[char] || KEY_MIRROR_MAP_R[char]
      combinations = combinations.product([char, mirror_key].compact).map(&:flatten)
    end

    combinations
  end

  def three_d_key_combinations(chord)
    combinations = [[]]
    chord.each do |char|
      three_d_key = get_three_d_key(char)
      next unless three_d_key

      combinations = combinations.product([char, three_d_key].compact).map(&:flatten)
    end

    combinations
  end

  def get_three_d_key(char)
    KEY_FINGER_MAP.each do |finger, chars|
      return "#{finger}_Center" if chars.include?(char)
    end

    nil
  end

  def words
    @_words ||= begin
      words = []
      File.foreach(FILE_NAME) do |line|
        words << line.chomp.downcase
      end
      words.uniq
    end
  end

  def sorted_words
    @_sorted_words ||= begin
      words_with_index = words.each_with_index.to_a
      sorted = words_with_index.sort_by { |word, index| [word.length, index] }
      sorted.map(&:first)
    end
  end
end

ChordGenerator.new.generate
