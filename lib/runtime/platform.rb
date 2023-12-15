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
    end
  end
end
