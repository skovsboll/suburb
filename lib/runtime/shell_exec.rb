# frozen_string_literal: true

require_relative '../util/command_printer'
require_relative './platform'

module Suburb
  module Runtime
    class ShellExec
      include Platform

      def initialize(log)
        @cmd = TTY::Command.new(printer: Util::CommandPrinter.new(log))
        @direct = TTY::Command.new(printer: :pretty)
      end

      def run(command)
        @cmd.run(command)
      rescue TTY::Command::ExitError => e
        raise Runtime::RuntimeError, e.message
      end

      def rtx(command, **kw)
        if os != :windows
          run("rtx x -- #{command}", **kw)
        else
          run(command)
        end
      end

      def cp(ins, outs)
        unless ins.size == outs.size
          raise Runtime::RuntimeError,
                "For the 'cp' (copy) command to work, there must be an equal number of ins and outs. There are #{ins.size} ins and #{outs.size} outs. "
        end

        ins.zip(outs) do |in_, out_|
          run "cp #{in_} #{out_}"
        end
      end
    end
  end
end
