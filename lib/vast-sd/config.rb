require 'json'

require 'tty-logger'
require 'tty-prompt'

require_relative './vast'

module VastSd
  class Config
    include Vast

    def initialize(path: ,config:)
      @path = path
      @config = config

      @logger = TTY::Logger.new
    end

    def run
      preferred_gpus = pick_preferred_gpus
      models = pick_models

      if File.exists?(@path) && !ask_boolean("Do you want to overwrite your current configuration file? (y/n)")
        return
      end

      File.write(@path, JSON.pretty_generate({
        preferred_gpus: preferred_gpus,
        models: models
      }))

      @logger.success "Configuration saved at:", @path
    end

    def pick_preferred_gpus
      prompt = TTY::Prompt.new

      offers = vast_cmd("search", "offers")

      gpus_selection = offers.map do |offer|
        offer["gpu_name"]
      end.uniq

      prompt.multi_select("Select your preferred GPU types", gpus_selection.sort, default: "RTX 4090", per_page: 20)
    end

    def pick_models

      {}.tap do |models|
        loop do
          if !ask_boolean("Do you want to add #{models.count == 0 ? "a" : "another"} model? (y/n)")
            break
          end

          model_kind = pick_model_kind

          uri = ask_uri("Public URI of the model:").to_s

          models[model_kind] ||= []
          models[model_kind].push(uri)

          @logger.success "Model added:", File.basename(uri)
        end
      end
    end

    def pick_model_kind
      prompt = TTY::Prompt.new

      prompt.select("What kind of model do you want to add?", ["Stable-diffusion", "Lora"])
    end

    def ask_boolean(label)
      prompt = TTY::Prompt.new

      prompt.ask(label, convert: :boolean)
    end

    def ask_uri(label)
      prompt = TTY::Prompt.new

      prompt.ask(label, convert: :uri)
    end
  end
end
