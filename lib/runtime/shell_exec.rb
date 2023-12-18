# frozen_string_literal: true

require_relative '../util/command_printer'
require_relative './platform'

module Suburb
  module Runtime
    class ShellExec
      include Platform

      def initialize(log)
        @cmd = TTY::Command.new(printer: Util::CommandPrinter.new(log))
      end

      # @param [String] command
      # @return [TTY::Command::Result]
      def run(command)
        @cmd.run(command)
      rescue TTY::Command::ExitError => e
        raise Runtime::RuntimeError, e.message
      end

      # @param [String] filename
      # @param [TTY::Command::Result] result
      def write(filename, result)
        stdout, = result
        File.write filename, stdout
      end

      # @param [String] command
      # @param [Hash] kw
      # @return [TTY::Command::Result]
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

        ins.zip(outs).each do |in_, out_|
          if os != :windows
            run "cp #{in_} #{out_}"
          else
            run "Copy-Item #{in_} -Destination #{out_}"
          end
        end
      end
    end
  end
end
