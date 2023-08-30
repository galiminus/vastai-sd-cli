# vastai-sd-cli

Little CLI tool to run and provision Stable Diffusion on Vast.ai (WIP)

## Install

```
gem install vastai-sd-cli
```

Please follow the instructions to install vast-ai-cli here https://cloud.vast.ai/cli/. Don't forget to set your API key.


## Configuration

Honestly the simplest thing to do is to write the configuration file yourself in `~/.vast-sd.conf.json`. For example: 

```json
{
  "preferred_gpus": ["RTX 4090"],
  "models": {
    "Stable-diffusion": [
      "https://my-sd-models.s3.eu-west-1.amazonaws.com/furrystuff.safetensors"
    ],
    "Lora": [
      "https://my-sd-models.s3.eu-west-1.amazonaws.com/boring_e621.pt",
      "https://my-sd-models.s3.eu-west-1.amazonaws.com/more_details.safetensors",
      "https://my-sd-models.s3.eu-west-1.amazonaws.com/pixelartV3.safetensors",
      "https://my-sd-models.s3.eu-west-1.amazonaws.com/fursuit.ckpt"
    ]
  }
}
```

* `preferred_gpus`: not required, it will narrow down the selection of instances to the ones with your GPU of choice.
* `models`: not required either, each entry has a list of URL to download on the server to the `stable-diffusion-webui/models/$entry_name/` folder.

## Usage

Run `vast-sd start` and you'll be greeted with a selection of instances, pick the one you want and wait for initialization and provisioning.

*Note: killing the process will automatically destroy your instance. But you better double check on vast-ai.*
