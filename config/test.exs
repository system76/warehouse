use Mix.Config

config :warehouse,
  producer: {Broadway.DummyProducer, []}
