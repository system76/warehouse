defmodule Warehouse.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run Warehouse.Server
end
