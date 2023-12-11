require 'tty-progressbar'
require 'tty-option'
require 'tty-logger'

module Suburb
  module Runtime
    class Command
      include TTY::Option

      def initialize
        super
        @log = TTY::Logger.new do |config|
          config.handlers = [
            [:console, { output: $stdout, level: :info }],
            [Suburb::Util::MonochromeHandler, { output: File.open('suburb.log', 'w'), level: :debug }]
          ]
        end
      end

      usage do
        program 'suburb'

        desc 'The developer friendly build graph'

        no_command

        example <<~EOS
          Build and watch website
            $ suburb -w dist/index.html

          Run tests, even if no dependencies changed
            $ suburb -f test-results.txt

          Clean (remove) file all dependencies
            $ suburb --clean
        EOS
      end

      argument :files do
        arity zero_or_more
        desc 'The relative path(s) of the file(s) you want to build.'
      end

      flag :force do
        short '-f'
        long '--force'
        desc 'Force rebuilding file and all dependencies.'
      end

      flag :watch do
        short '-w'
        long '--watch'
        desc 'Watch file and dependencies (including transitive) for changes and rebuild as needed.'
      end

      flag :list do
        short '-l'
        long '--list'
        desc 'List the files that can be build in this directory, its parent or child directories.'
      end

      flag :tree do
        short '-t'
        long '--show-tree'
        desc 'Show a visual graph of the dependency tree.'
      end

      flag :clean do
        short '-c'
        long '--clean'
        desc 'Delete file and all its (transitive) dependencies.'
      end

      flag :help do
        short '-h'
        long '--help'
        desc 'Print usage'
      end

      def run
        if params[:help]
          print help
        elsif params.errors.any?
          @log.error params.errors.summary
          print help
        else
          run_suburb
        end
      end

      def run_suburb
        start_time = Time.new
        if params[:list]
          Lister.new(@log).run
        else
          runner = Runner.new(@log)
          files = Array(params[:files])
          run_files(files, runner)
          @log.info "Completed in #{format_elapsed(start_time, Time.new)}."
          @log.info 'Log file: cat ./suburb.log'
        end
      rescue CyclicDependencyError => e
        cyclic_dep_error(e, runner, start_time)
      rescue RuntimeError => e
        runtime_error(e, runner, start_time)
      end

      def cyclic_dep_error(e, runner, start_time)
        @log.debug e
        @log.error e.message
        @log.info runner.show_graph_tree(e.graph) if runner.iterm2?
        @log.info "Errored after #{format_elapsed(start_time, Time.new)}."
        @log.info 'Complete log: cat ./suburb.log'
      end

      def runtime_error(e, _runner, start_time)
        @log.debug e
        @log.error e.message
        @log.info "Errored after #{format_elapsed(start_time, Time.new)}."
        @log.info 'Complete log: cat ./suburb.log'
      end

      def run_files(files, runner)
        if files.any?
          files.each do |file|
            file_path = File.expand_path(file)
            if params[:clean]
              runner.clean(file_path)
            elsif params[:tree]
              if runner.iterm2?
                @log.info runner.show_tree_and_link(file_path)
              else
                @log.warn 'Run this in iTerm2 to show trees and links.'
              end
            else
              runner.run(file_path, force: params[:force])
            end
          end
        else
          print help
        end
      end

      def format_elapsed(start_time, end_time)
        elapsed = end_time - start_time
        if elapsed < 1.0
          "#{format('%.0f', (elapsed * 1000))} ms"
        elsif elapsed < 60
          "#{'%.0f' % elapsed} seconds"
        else
          "#{format('%.0f', (elapsed / 60))}:{'%.0f' % (elapsed % 60)}"
        end
      end
    end
  end
end
