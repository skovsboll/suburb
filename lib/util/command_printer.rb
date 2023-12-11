require 'tty-command'

module Suburb
  module Util
    class CommandPrinter < TTY::Command::Printers::Abstract
      def initialize(log)
        super
        raise 'Must provide a Logger for CommandPrinter' unless log

        @log = log
      end

      def print_command_start(cmd, *args)
        write(''"
#{'·' * 60}
#{cmd.to_command} #{args.join}
"'')
      end

      def print_command_out_data(_cmd, *stdout); end

      def print_command_err_data(_cmd, *stderr); end

      def print_command_exit(_cmd, *stdout)
        write(''"
#{stdout.join(' ')}
#{'·' * 60}
"'')
      end

      def write(message)
        @log.debug message
      end
    end
  end
end
