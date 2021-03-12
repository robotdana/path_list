# frozen-string-literal: true

class PathList
  class RootCandidate
    # :nocov:
    using ::PathList::Backports::DeletePrefixSuffix if defined?(::PathList::Backports::DeletePrefixSuffix)
    # :nocov:

    attr_reader :full_path

    def initialize(full_path, filename, directory, content)
      @full_path = full_path
      @filename = filename
      (@directory = directory) unless directory.nil?
      @first_line = content
    end

    def parent
      @parent ||= ::PathList::RootCandidate.new(
        ::File.dirname(@full_path),
        nil,
        true,
        nil
      )
    end

    def relative_to(dir)
      return unless @full_path.start_with?(dir)

      ::PathList::RelativeCandidate.new(@full_path.delete_prefix(dir), self)
    end

    def directory?
      return @directory if defined?(@directory)

      @directory ||= ::File.directory?(@full_path)
    end

    def filename
      @filename ||= ::File.basename(@full_path)
    end

    # how long can a shebang be?
    # https://www.in-ulm.de/~mascheck/various/shebang/
    # 512 feels like a reasonable limit
    def first_line
      @first_line ||= begin
        file = ::File.new(@full_path)
        first_line = file.sysread(512)
        file.close
        first_line || ''
      rescue ::EOFError, ::SystemCallError
        # :nocov:
        file&.close
        # :nocov:
        first_line || ''
      end
    end
  end
end
