require 'rbconfig'

module Suburb
  module Runtime
    module Platform
      def os
        case (host_os = RbConfig::CONFIG['host_os'])
        when /mswin|mingw|windows/i
          :windows
        when /linux|unix/i
          :linux
        when /darwin|mac os/i
          :macos
        else
          host_os
        end
      end

      def cpu
        RbConfig::CONFIG['host_cpu'].to_sym
      end

      def shell
        shell_path = ENV['SHELL'] || ENV['COMSPEC']

        return :bash if shell_path&.include?('bash')
        return :zsh if shell_path&.include?('zsh')
        return :pwsh if shell_path&.include?('pwsh')
        return :sh if shell_path&.include?('/sh') # Generic sh
        return :cmd if shell_path&.include?('cmd.exe') # Windows Command Prompt
        return :powershell if shell_path&.include?('powershell')

        :unknown
      end
    end
  end
end
