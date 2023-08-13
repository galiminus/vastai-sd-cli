require 'shellwords'
require 'json'

require 'tty-spinner'
require 'tty-command'

module VastSd
  module Vast
    def vast_cmd(*params)
      spinner = TTY::Spinner.new(clear: true)
      spinner.auto_spin
    
      cmd = TTY::Command.new(printer: :null)
    
      params = params.map do |param|
        Shellwords.escape(param)
      end
    
      output, error = cmd.run("vast #{params.join(" ")} --raw 2> /dev/null")
    
      # Cleanup output
      output = output.gsub(/.+HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHh/m, '')
    
      spinner.stop
    
      begin
        JSON.parse(output)
      rescue JSON::ParserError
        output
      end
    end
  end
end
