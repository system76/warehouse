defmodule WarehouseGRPC.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run WarehouseGRPC.Server
end
