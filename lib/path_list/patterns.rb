# frozen-string-literal: true

class PathList
  class Patterns
    def initialize(*patterns, from_file: nil, format: :gitignore, root: nil)
      raise ArgumentError, "from_file: can't be used with patterns arguments" unless patterns.empty? || !from_file

      @format = format
      if from_file
        @root = root || ::File.dirname(from_file)
        @patterns = ::File.exist?(from_file) ? ::File.readlines(from_file) : []
      else
        @root = root || ::Dir.pwd
        @patterns = patterns.flatten.flat_map { |string| string.to_s.lines }
      end
      @root += '/' unless @root.end_with?('/')
    end

    def build_matchers(include: false)
      matchers = @patterns.flat_map { |p| ::PathList::RuleBuilder.build(p, include, @format, @root) }

      return if matchers.empty?
      return [::PathList::Matchers::WithinDir.new(matchers, @root)] unless include

      [
        ::PathList::Matchers::WithinDir.new(matchers, @root),
        ::PathList::Matchers::WithinDir.new(
          ::PathList::GitignoreIncludeRuleBuilder.new(@root).build_as_parent, '/'
        )
      ]
    end
  end
end
