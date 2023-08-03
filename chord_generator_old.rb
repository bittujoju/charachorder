require "csv"

class ChordGenerator
  MIN_CHORD_LENGTH = 2.freeze
  MIN_WORD_LENGTH = 2.freeze
  ALT_KEYS = %w(LEFT_ALT RIGHT_ALT).freeze
  # Setting this to true will cause shorter words to have shorter chords
  # and longer words to have longer chords
  LENGTH_PROPORTIONAL = false.freeze
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
    "g" => "DUP",
    "x" => nil
  }.freeze
  KEY_MIRROR_MAP_R = KEY_MIRROR_MAP_L.invert.freeze
  KEY_FINGER_MAP = {
     "LH_PINKY" => %w(LEFT_ALT),
     "LH_RING_1" => %w(, u '),
     "LH_MID_1" => %w(. o i),
     "LH_INDEX" => %w(e r),
     "LH_THUMB_1" => %w(m v k c),
     "LH_THUMB_2" => %w(g z w),
     "RH_THUMB_2" => %w(x b q),
     "RH_THUMB_1" => %w(p f d h),
     "RH_INDEX" => %w(a t),
     "RH_MID_1" => %w(l n j),
     "RH_RING_1" => %w(y s ;),
     "RH_PINKY" => %w(RIGHT_ALT)
  }.freeze
  CONFLICTING_FINGER_GROUPS = {
    "LH_PINKY" => %w(LEFT_ALT LH_PINKY_3D),
    "LH_RING_1" => %w(, u ' LH_RING_1_3D),
    "LH_MID_1" => %w(. o i LH_MID_1_3D),
    "LH_INDEX" => %w(e r LH_INDEX_3D),
    "LH_THUMB" => %w(m v k c LH_THUMB_1_3D g z w LH_THUMB_1_3D),
    "RH_THUMB" => %w(x b q DUP RH_THUMB_1_3D p f d h RH_THUMB_2_3D),
    "RH_INDEX" => %w(a t RH_INDEX_3D),
    "RH_MID_1" => %w(l n j RH_MID_1_3D),
    "RH_RING_1" => %w(y s ; RH_RING_1_3D),
    "RH_PINKY" => %w(RIGHT_ALT RH_PINKY_3D)
  }.freeze

  # Rearrange the order of the following array to your preference
  # ie, if you want to use 3d keys before using alt move use_3d_keys before use_alt_keys
  CHORD_GENERATOR_LOGIC = %i[
    skip_keys
    all_keys
    use_mirror_keys
    use_alt_keys
    use_3d_keys
  ].freeze

  def initialize(words_file, chords_file)
    @used_chords = {}
    @words_file = words_file
    @chords_file = chords_file
  end

  def generate
    words_list.each do |word|
      raise "Word is blank" if word.nil?
      next if word.length < MIN_WORD_LENGTH

      chord = calculate_chord(get_chars(word))
      unless chord
        puts "Could not generate chord for #{word}"
        next
      end

      assign_chord(word, chord)
      create_csv!
    end
  end

  def create_csv!
    CSV.open(@chords_file, "w") do |csv|
      @used_chords.each do |word, chord|
        csv << [chord.join(" + "), word]
      end
    end
  end

  def words_list
    return sorted_words if LENGTH_PROPORTIONAL

    words
  end

  def calculate_chord(chars)
    CHORD_GENERATOR_LOGIC.each do |logic|
      chord = send(logic, chars)

      return chord if chord
    end

    nil
  end

  def get_chars(word)
    chars = word.chars
    return chars.uniq.push("DUP") if has_duplicates?(chars)

    chars.uniq
  end

  def assign_chord(word, chord)
    @used_chords[word] = chord.sort
  end

  def skip_keys(chars)
    chord = []
    chars.each_with_index do |char, index|
      chord << char
      next chord.pop if finger_conflict?(chord)
      next if (index + 1) < MIN_CHORD_LENGTH
      next chord.pop if used_chord?(chord)

      return chord
    end

    nil
  end

  def all_keys(chars)
    chord = []
    chars.each_with_index do |char, index|
      chord << char
      next chord.pop if finger_conflict?(chord)
      next if (index + 1) < MIN_CHORD_LENGTH
      next if used_chord?(chord)

      return chord
    end

    nil
  end

  def use_mirror_keys(chars)
    chord = []
    chars.each_with_index do |char, index|
      chord << char
      next if (index + 1) < MIN_CHORD_LENGTH

      mirror_key_combinations(chord).each do |mirror_chord|
        next if finger_conflict?(mirror_chord)
        next if used_chord?(mirror_chord)

        return mirror_chord
      end
    end

    nil
  end

  def use_3d_keys(chars)
    chord = []
    chars.each_with_index do |char, index|
      chord << char
      next if (index + 1) < MIN_CHORD_LENGTH

      three_d_key_combinations(chord).each do |three_d_chord|
        next if finger_conflict?(chord)
        next if used_chord?(three_d_chord)

        return three_d_chord
      end
    end

    nil
  end

  def use_alt_keys(chars)
    ALT_KEYS.each do |alt_key|
      chars_with_alt = chars + [alt_key]
      chord = []
      chars_with_alt.each_with_index do |char, index|
        chord << char
        next chord.pop if finger_conflict?(chord)
        next if (index + 1) < MIN_CHORD_LENGTH
        next if used_chord?(chord)

        return chord
      end
    end

    nil
  end

  def finger_conflict?(chord)
    return true if has_duplicates?(chord)

    CONFLICTING_FINGER_GROUPS.values.any? do |finger_keys|
      (finger_keys & chord).size > 1
    end
  end

  def has_duplicates?(chord)
    chord.size > chord.uniq.size
  end

  def used_chord?(chord)
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
      return "#{finger}_3D" if chars.include?(char)
    end

    nil
  end

  def words
    @_words ||= begin
      words = []
      File.foreach(@words_file) do |line|
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

# Replace words.txt with the path to your words file
ChordGenerator.new("words.txt", "chords.csv").generate

