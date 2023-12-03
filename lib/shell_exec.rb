# frozen_string_literal: true

require 'rbconfig'

module Suburb
  class ShellExec

    def initialize(log)
      @cmd = TTY::Command.new(output: log, color: false, uuid: false)
    end

    def sh(command)
      @cmd.run(command) do |_out, err|
        raise Suburb::RuntimeError, err if err
      end
    end

    def rtx(command)
      @cmd.run("rtx x -- #{command}") do |_out, err|
        raise Suburb::RuntimeError, err if err
      end
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
