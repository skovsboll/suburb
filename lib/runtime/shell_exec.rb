# frozen_string_literal: true

require 'rbconfig'
require_relative '../util/command_printer'

module Suburb
  module Runtime
    class ShellExec
      def initialize(log)
        @cmd = TTY::Command.new(printer: Util::CommandPrinter.new(log))
        @direct = TTY::Command.new(printer: :pretty)
      end

      def sh(command, stdout: false)
        if stdout
          @direct.run(command)
        else
          @cmd.run(command)
        end
      rescue TTY::Command::ExitError => e
        raise Runtime::RuntimeError, e.message
      end

      def rtx(command, **kw)
        sh("rtx x -- #{command}", **kw)
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
          raise Runtime::RuntimeError,
                "For the 'cp' (copy) command to work, there must be an equal number of ins and outs. There are #{ins.size} ins and #{outs.size} outs. "
        end

        ins.zip(outs) do |in_, out_|
          sh "cp #{in_} #{out_}"
        end
      end
    end
  end
end
