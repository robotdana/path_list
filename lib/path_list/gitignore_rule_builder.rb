# frozen_string_literal: true

class PathList
  class GitignoreRuleBuilder # rubocop:disable Metrics/ClassLength
    def initialize(rule)
      @re = ::PathList::PathRegexpBuilder.new
      @s = ::PathList::GitignoreRuleScanner.new(rule)

      @negation = false
      @anchored = false
      @dir_only = false
    end

    def break!
      throw :break
    end

    def blank!
      throw :abort_build, []
    end

    def unmatchable_rule!
      throw :abort_build, []
    end

    def negated!
      @negation = true
    end

    def anchored!
      @anchored ||= true
    end

    def never_anchored!
      @anchored = :never
    end

    def dir_only!
      @dir_only = true
    end

    def nothing_emitted?
      @re.empty?
    end

    def emit_dir
      anchored!
      @re.append_dir
    end

    def emit_any_dir
      anchored!
      @re.append_any_dir
    end

    def emit_end
      @re.append_end_anchor
      break!
    end

    def process_backslash
      return unless @s.backslash?

      @re.append_escaped(@s.next_character) || unmatchable_rule!
    end

    def process_star_end_after_slash # rubocop:disable Metrics/MethodLength
      if @s.star_end?
        @re.append_many_non_dir
        emit_end
      elsif @s.two_star_end?
        break!
      elsif @s.star_slash_end?
        @re.append_many_non_dir
        dir_only!
        emit_end
      elsif @s.two_star_slash_end?
        dir_only!
        break!
      else
        true
      end
    end

    def process_slash
      return unless @s.slash?
      return dir_only! if @s.end?
      return unmatchable_rule! if @s.slash?

      emit_dir
      process_star_end_after_slash
    end

    def process_two_stars # rubocop:disable Metrics/MethodLength
      return unless @s.two_stars?
      return break! if @s.end?

      if @s.slash?
        if @s.end?
          @re.append_any_non_dir
          dir_only!
        elsif @s.slash?
          unmatchable_rule!
        else
          if nothing_emitted?
            never_anchored!
          else
            emit_any_dir
          end
          process_star_end_after_slash
        end
      else
        @re.append_any_non_dir
      end
    end

    def process_character_class # rubocop:disable Metrics/MethodLength
      return unless @s.character_class_start?

      @re.append_character_class_open
      @re.append_character_class_negation if @s.character_class_negation?
      unmatchable_rule! if @s.character_class_end?

      until @s.character_class_end?
        next if process_backslash
        next @re.append_character_class_dash if @s.dash?
        next if @re.append_escaped(@s.character_class_literal)

        unmatchable_rule!
      end

      @re.append_character_class_close
    end

    def process_end
      blank! if nothing_emitted?

      emit_end
    end

    def process_rule # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      anchored! if @s.slash?

      catch :break do
        loop do
          next if process_backslash
          next if process_slash
          next if process_two_stars
          next @re.append_any_non_dir if @s.star?
          next @re.append_one_non_dir if @s.question_mark?
          next if process_character_class
          next if @re.append_escaped(@s.literal)
          next if @re.append_escaped(@s.significant_whitespace)

          process_end
        end
      end
    end

    def prefix
      out = ::PathList::PathRegexpBuilder.new

      if @anchored
        out.append_start_anchor
      else
        out.append_dir_or_start_anchor
      end
      out
    end

    def build_rule
      @re.prepend(prefix)
      if @negation
        ::PathList::Matchers::AllowPathRegexp.new(@re.to_regexp, @anchored, @dir_only)
      else
        ::PathList::Matchers::IgnorePathRegexp.new(@re.to_regexp, @anchored, @dir_only)
      end
    end

    def build
      catch :abort_build do
        blank! if @s.hash?
        negated! if @s.exclamation_mark?
        process_rule

        @anchored = false if @anchored == :never

        build_rule
      end
    end
  end
end
