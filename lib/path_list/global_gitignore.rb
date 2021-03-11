# frozen_string_literal: true

class PathList
  module GlobalGitignore
    class << self
      def path(root:)
        gitconfig_gitignore_path(::File.expand_path('.git/config', root)) ||
          gitconfig_gitignore_path(::File.expand_path('~/.gitconfig')) ||
          gitconfig_gitignore_path(xdg_config_path) ||
          gitconfig_gitignore_path('/etc/gitconfig') ||
          default_global_gitignore_path
      end

      private

      def gitconfig_gitignore_path(config_path)
        return unless config_path
        return unless ::File.exist?(config_path)

        ignore_path = ::File.readlines(config_path).find { |l| l.sub!(/\A\s*excludesfile\s*=/, '') }
        return unless ignore_path

        ignore_path.strip!
        return ignore_path if ignore_path.empty? # don't expand path in this case

        ::File.expand_path(ignore_path)
      end

      def xdg_config_path
        xdg_config_home? && ::File.expand_path('git/config', xdg_config_home)
      end

      def default_global_gitignore_path
        if xdg_config_home?
          ::File.expand_path('git/ignore', xdg_config_home)
        else
          ::File.expand_path('~/.config/git/ignore')
        end
      end

      def xdg_config_home
        ::ENV['XDG_CONFIG_HOME']
      end

      def xdg_config_home?
        xdg_config_home && (not xdg_config_home.empty?)
      end
    end
  end
end
