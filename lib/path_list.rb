# frozen_string_literal: true

require_relative './path_list/backports'

require 'set'
require 'strscan'
require_relative 'path_list/rule_groups'
require_relative 'path_list/global_gitignore'
require_relative 'path_list/rule_builder'
require_relative 'path_list/gitignore_rule_builder'
require_relative 'path_list/gitignore_include_rule_builder'
require_relative 'path_list/path_regexp_builder'
require_relative 'path_list/gitignore_rule_scanner'
require_relative 'path_list/rule_group'
require_relative 'path_list/matchers/unmatchable'
require_relative 'path_list/matchers/shebang_regexp'
require_relative 'path_list/root_candidate'
require_relative 'path_list/relative_candidate'
require_relative 'path_list/matchers/within_dir'
require_relative 'path_list/matchers/allow_any_dir'
require_relative 'path_list/matchers/allow_path_regexp'
require_relative 'path_list/matchers/ignore_path_regexp'
require_relative 'path_list/patterns'
require_relative 'path_list/walkers/file_system'
require_relative 'path_list/walkers/gitignore_collecting_file_system'
require_relative 'path_list/gitignore_rule_group'

class PathList
  class Error < StandardError; end

  include ::Enumerable

  # :nocov:
  using ::PathList::Backports::DeletePrefixSuffix if defined?(::PathList::Backports::DeletePrefixSuffix)
  using ::PathList::Backports::DirEachChild if defined?(::PathList::Backports::DirEachChild)
  # :nocov:

  def initialize(root: nil, gitignore: :auto, **rule_group_builder_args)
    @root = "#{::File.expand_path(root.to_s, Dir.pwd)}/"
    rule_groups = ::PathList::RuleGroups.new(root: @root, gitignore: gitignore, **rule_group_builder_args)

    walker_class = gitignore ? ::PathList::Walkers::GitignoreCollectingFileSystem : ::PathList::Walkers::FileSystem
    @walker = walker_class.new(rule_groups)
    freeze
  end

  def allowed?(path, directory: nil, content: nil)
    @walker.allowed?(path, directory: directory, content: content)
  end
  alias_method :===, :allowed?

  def to_proc
    method(:allowed?).to_proc
  end

  def each(root = ::Dir.pwd, &block)
    return enum_for(:each, root) unless block_given?

    root = "#{::File.expand_path(root.to_s, Dir.pwd)}/"
    @walker.each(root, '', &block)
  end
end
