# frozen_string_literal: true

require_relative '../util/command_printer'
require_relative './platform'
require 'fileutils'

module Suburb
  module Runtime
    class ShellExec
      include Platform

      def initialize(log)
        @cmd = TTY::Command.new(printer: Util::CommandPrinter.new(log))
      end

      # @param [String] command
      # @return [TTY::Command::Result]
      def run(command, &block)
        @cmd.run(command, &block)
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
      def rtx(command, **kw, &block)
        if os != :windows
          run("rtx x -- #{command}", **kw, &block)
        else
          run(command, &block)
        end
      end

      def cp(ins, outs)
        unless ins.size == outs.size
          raise Runtime::RuntimeError,
                "For the 'cp' (copy) command to work, there must be an equal number of ins and outs. There are #{ins.size} ins and #{outs.size} outs. "
        end

        ins.zip(outs).each do |in_, out_|
          FileUtils.cp(in_, out_)
        end
      end
    end
  end
end
