# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :ueberauth, Ueberauth,
  providers: [
    facebook: {Ueberauth.Strategy.Facebook, [profile_fields: "email,name"]},
    google: {Ueberauth.Strategy.Google, [default_scope: "email"]}
  ]

config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: "1048553195181028",
  client_secret: "144b6cce9d58127303d5370436c0d604"

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "314131318928-ga8ljbm1424g8ulkaosolgp9houskcmj.apps.googleusercontent.com",
  client_secret: "lgayFMi3s-m7uzUv3lciFfIf"


# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :frex, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:frex, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
