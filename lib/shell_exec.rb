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
      case (host_os = RbConfig::CONFIG['host_os'])
      when /mswin|windows/i
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

    def cp(ins, outs)
      unless ins.size == outs.size
        raise Suburb::RuntimeError,
              "For the copy command to work, there must be an equal number of ins and outs. There are #{ins.size} ins and #{outs.size} outs. "
      end

      ins.zip(outs) do |in_, out_|
        sh "cp #{in_} #{out_}"
      end
    end
  end
end
