# frozen_string_literal: true

require 'rbconfig'

module Suburb
  class Exec
    def initialize(log)
      @log = log
      @cmd = TTY::Command.new(output: @log, color: false, uuid: false)
    end

    def rtx(command)
      @cmd.run("rtx x -- #{command}") do |_out, err|
        raise Err, err if err
      end
    end

    def sh(command)
      @cmd.run(command) do |_out, err|
        raise Err, err if err
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
        :unnkown
      end
    end
  end
end
