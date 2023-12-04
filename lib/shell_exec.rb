# frozen_string_literal: true

require 'rbconfig'

module Suburb
  class ShellExec
    def initialize(log)
      @cmd = TTY::Command.new(output: log, color: false, uuid: false)
    end

    def sh(command)
      out, = @cmd.run(command)
      out.strip
    rescue TTY::Command::ExitError => e
      raise Suburb::RuntimeError, e.message
    end

    def rtx(command)
      sh "rtx x -- #{command}"
    end

    def os
      case RbConfig::CONFIG['host_os']
      when /mswin|windows/i
        :windows
      when /linux|unix/i
        :linux
      when /darwin|mac os/i
        :macos
      else
        :unknown
      end
    end
  end
end
