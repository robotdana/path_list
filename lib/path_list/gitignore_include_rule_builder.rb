# frozen_string_literal: true

class PathList
  class GitignoreIncludeRuleBuilder < GitignoreRuleBuilder
    # :nocov:
    using ::PathList::Backports::DeletePrefixSuffix if defined?(::PathList::Backports::DeletePrefixSuffix)
    # :nocov:

    def initialize(rule, expand_path_with: nil)
      super(rule)

      @negation = true
      @expand_path_from = expand_path_with
    end

    def expand_rule_path
      anchored! unless @s.match?(/\*/)
      return unless @s.match?(%r{(?:[~/]|\.{1,2}/|.*/\.\./)})

      dir_only! if @s.match?(%r{.*/\s*\z})
      @s.string.replace(::File.expand_path(@s.rest))
      @s.string.delete_prefix!(@expand_path_from)
      @s.pos = 0
    end

    def negated!
      @negation = false
    end

    def unmatchable_rule!
      throw :abort_build, ::PathList::Matchers::Unmatchable
    end

    def emit_end
      if @dir_only
        @child_re = @re.dup
        @re.append_end_anchor
      else
        @re.append_dir_or_end_anchor
      end

      break!
    end

    def build_parent_dir_rules
      return unless @negation

      if @anchored
        parent_pattern = @s.string.dup
        if parent_pattern.sub!(%r{/[^/]+/?\s*\z}, '/')
          ::PathList::GitignoreIncludeRuleBuilder.new(parent_pattern).build_as_parent
        end
      else
        [::PathList::Matchers::AllowAnyDir]
      end
    end

    def build_child_file_rule # rubocop:disable Metrics/MethodLength
      if @child_re.end_with?('/')
        @child_re.append_many_non_dir.append_dir if @dir_only
      else
        @child_re.append_dir
      end

      @child_re.prepend(prefix)

      if @negation
        ::PathList::Matchers::AllowPathRegexp.new(@child_re.to_regexp, @anchored, false)
      else
        ::PathList::Matchers::IgnorePathRegexp.new(@child_re.to_regexp, @anchored, false)
      end
    end

    def build_as_parent
      anchored!
      dir_only!

      catch :abort_build do
        process_rule
        build_rule(child_file_rule: false)
      end
    end

    def build_rule(child_file_rule: true)
      @child_re ||= @re.dup # in case emit_end wasn't called

      [super(), *build_parent_dir_rules, (build_child_file_rule if child_file_rule)].compact
    end

    def process_rule
      expand_rule_path if @expand_path_from
      super
    end
  end
end
