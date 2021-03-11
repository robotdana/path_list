# frozen_string_literal: true

class PathList
  module Matchers
    module AllowAnyDir
      class << self
        def squash_id
          :allow
        end

        def dir_only?
          true
        end

        def file_only?
          false
        end

        def shebang?
          false
        end

        # :nocov:
        def inspect
          '#<AllowAnyDir>'
        end
        # :nocov:

        def match?(_)
          :allow
        end
      end
    end
  end
end
