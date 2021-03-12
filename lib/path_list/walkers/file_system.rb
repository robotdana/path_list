# frozen-string-literal: true

class PathList
  module Walkers
    class FileSystem
      # :nocov:
      using ::PathList::Backports::DirEachChild if defined?(::PathList::Backports::DirEachChild)
      # :nocov:

      def initialize(rule_groups)
        @rule_groups = rule_groups
      end

      def allowed?(path, directory: nil, content: nil)
        full_path = ::File.expand_path(path)

        return false if directory.nil? ? ::File.lstat(full_path).directory? : directory

        candidate = ::PathList::RootCandidate.new(full_path, nil, directory, content)
        @rule_groups.allowed_recursive?(candidate)
      rescue ::Errno::ENOENT, ::Errno::EACCES, ::Errno::ENOTDIR, ::Errno::ELOOP, ::Errno::ENAMETOOLONG
        false
      end

      def each(parent_full_path, parent_relative_path, &block) # rubocop:disable Metrics/MethodLength
        children = ::Dir.children(parent_full_path)

        children.each do |filename|
          begin
            full_path = parent_full_path + filename
            relative_path = parent_relative_path + filename
            dir = ::File.lstat(full_path).directory?
            candidate = ::PathList::RootCandidate.new(full_path, filename, dir, nil)

            next unless @rule_groups.allowed_unrecursive?(candidate)

            if dir
              each(full_path + '/', relative_path + '/', &block)
            else
              yield relative_path
            end
            # :nocov: TODO: add cov
          rescue ::Errno::ENOENT, ::Errno::EACCES, ::Errno::ENOTDIR, ::Errno::ELOOP, ::Errno::ENAMETOOLONG
            nil
            # :nocov:
          end
        end
      end
    end
  end
end
