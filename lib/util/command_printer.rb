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

current dir: #{Dir.pwd}
"'')
      end

      def print_command_out_data(_cmd, *stdout)
        for line in stdout
          begin
            write line unless line.empty?
          rescue Encoding::CompatibilityError
          end
        end
      end

      def print_command_err_data(_cmd, *stderr)
        for line in stderr
          begin
            write line unless line.empty?
          rescue Encoding::CompatibilityError
          end
        end
      end

      def print_command_exit(_cmd, *stdout)
        write(''"
#{stdout.join(' ')}
#{'·  ' * 20}
"'')
      end

      def write(message)
        @log.debug message
      end
    end
  end
end
