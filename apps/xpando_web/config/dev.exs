import Config

# Configure Tidewave to find the root of your umbrella project.
# This is the only development-specific setting needed here,
# as everything else is set in the root config file.
config :tidewave,
  root: Path.expand("../..", __DIR__)
