require 'shellwords'
require 'json'
require 'tty-logger'
require 'tty-spinner'
require 'tty-prompt'

require_relative './vast'

module VastSd
  class Start
    include Vast

    def initialize(config:)
      @config = config
    end

    def run
      logger = TTY::Logger.new
      prompt = TTY::Prompt.new

      user_info = vast_cmd("show", "user")
      logger.info "Credit balance", sprintf("$%2.2f", user_info["credit"])

      offers = vast_cmd("search", "offers")

      offers = offers.select do |offer|
        has_good_gpu =
          if @config["preferred_gpus"].to_a.count > 0
            @config["preferred_gpus"].include?(offer["gpu_name"])
          else
            true
          end

        has_good_gpu && offer["rentable"]
      end.sort_by do |offer|
        offer["dph_total"]
      end

      id = prompt.select("Instance selection", offers.map { |offer|
        {
          name: sprintf("%-40s %s", "#{offer['num_gpus']} #{offer["gpu_name"]} - #{offer["geolocation"]}", sprintf("$%2.2f/hr", offer["dph_total"])),
          value: offer["id"]
        }
      }, per_page: 20)

      contract = vast_cmd(
        "create",
        "instance", id,
        "--disk", 50,
        "--jupyter",
        "--jupyter-dir", "/",
        "--direct",
        "--env", "-e JUPYTER_DIR=/ -p 3000:3000",
        "--onstart-cmd", %{
          sed -i '/rsync -au --remove-source-files \/venv\/ \/workspace\/venv\//a source \/workspace\/venv\/bin\/activate\n pip install jupyter_core' /start.sh;
          /start.sh
        },
        "--image", @config["image"] || "runpod/stable-diffusion:web-automatic-10.1.1"
      )

      contract_id = contract["new_contract"]

      at_exit do
        vast_cmd("destroy", "instance", contract_id)

        logger.success "Instance destroyed"
      end

      logger.success "Contract ID", contract_id

      # Wait until instance is ready
      TTY::Spinner.new("[:spinner] Waiting for instance: :status", clear: true).run do |spinner|
        loop do
          instance = vast_cmd("show", "instance", contract_id)

          spinner.update status: instance["actual_status"] || "Initialization"

          if instance["actual_status"] == "running"
            port = instance["ports"]["3000/tcp"][0]["HostPort"]

            logger.info "http://#{instance["public_ipaddr"]}:#{port}"

            break
          else
            sleep 5
          end
        end
      end

      ssh_info = vast_cmd('ssh-url', contract_id)
      logger.info ssh_info

      @config["models"].entries.each do |namespace, urls|
        urls.each do |url|
          TTY::Spinner.new("[:spinner] Loading \"#{File.basename(url)}\" in models/#{namespace}", clear: true).run do
            upload_cmd = "curl #{Shellwords.escape(url)} -o /workspace/stable-diffusion-webui/models/#{namespace}/#{File.basename(url)}"

            loop do
              system("ssh -o StrictHostKeyChecking=no -q #{Shellwords.escape(ssh_info.chomp)} #{Shellwords.escape(upload_cmd)} &> /dev/null")
              break if $? == 0
            end
          end
        end
      end

      logger.success "Instance ready"

      # Run watchdog
      spinner = TTY::Spinner.new("[:spinner] Running: :balance")
      spinner.auto_spin

      loop do
        begin
          user_info = vast_cmd("show", "user")
          spinner.update balance: "credit balance #{sprintf("$%2.2f", user_info["credit"])}"

          instance = vast_cmd("show", "instance", contract_id)

          if instance["actual_status"] != "running"
            logger.error "Instance #{instance['actual_status']}"
            exit
          else
            sleep 60
          end
        rescue Interrupt
          exit(0)
        end
      end

      spinner.stop
    end
  end
end
