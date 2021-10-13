<div align="center">
  <h1>Warehouse</h1>
  <h3>An inventory tracking microservice</h3>
  <br>
  <br>
</div>

---

> **NOTE**: This micro service is not fully written yet, and includes references
> to database records, processes, and workflows that are not yet implemented in
> here.

This repository contains the code that System76 uses to manage it's warehouse of
computer parts. It is responsible for:

- Creating POs with vendors to receive new parts
- Manage receiving new parts from vendors
- Manage kitting and the relationship between what we have in inventory and what
  is requested from the e-commerce orders.
- Calculating and tracking the demand for different SKUs in our system (available, back ordered, etc)

## Communication

This micro service works very closely with (and is dependent on)
[the Assembly service](https://github.com/system76/assembly). The assembly
service is responsible for tracking build details. They have a relationship like
so:

```
Assembly ------------------------------------------------------------> Warehouse

This is a gRPC request from Assembly to Warehouse to determine the
`Warehouse.Schema.Component` quantity available. This is used to determine if a
`Assembly.Schemas.Build` has all of the needed parts in stock to build. A
similar RabbitMQ message is broadcasted when that quantity changes.

Assembly <------------------------------------------------------------ Warehouse

This is a gRPC request from Warehouse to Assembly to determine the demand of
`Warehouse.Schema.Component`. This allows Warehouse to determine the back order
status of a `Warehouse.Schema.Sku` and the quantity we need to order. A similar
RabbitMQ message is broadcasted when this quantity changes.
```

## Schemas

This micro service as a couple of schemas it uses, but two stand out as the
cornerstones.

```
        component_1             component_2              <- `Warehouse.Schemas.Component`
       /           \           /           \
      /             \         /             \            <- `Warehouse.Schemas.Kit`
     /               \       /               \
sku_1                 sku_two                 sku_two    <- `Warehouse.Schemas.Sku`
```

The `Warehouse.Schemas.Component` schema connects our e-ecommerce platform and
assembly system to inventory. Anything that gets sold is a component. When you
purchase a computer, every component selected (and some hidden components), are
added to a build. These components are represented as a very basic, customer
facing names like `NVIDIA RTX 3080`.

The `Warehouse.Schemas.Sku` schema is our lower level inventory system. This
is a much more specific product that we buy from vendors, like
`MSI GeForce RTX 3080 GAMING X TRIO 10GB`, or `G3080GXT10`.

The `Warehouse.Schemas.Kit` schema is how we combine the other two schemas.
Every `Warehouse.Schemas.Component` can be fulfilled by any selected
`Warehouse.Schemas.Sku`, and most `Warehouse.Schemas.Sku`s can be used by
multiple `Warehouse.Schemas.Component`s. This comes into play with more complex
configurations like memory. A pseudo example of this:

```
%Component{id: 1, name: "32 GB DDR4 @ 3200 MHz Desktop Memory"}

%Kit{component_id: 1, sku_id: 1, quantity: 4}
%Sku{sku_id: 1, name: "Kingston 8 GB DDR4 at 3200 MHz"}

%Kit{component_id: 1, sku_id: 2, quantity: 4}
%Sku{sku_id: 2, name: "Crucial 16 GB DDR4 at 3200 MHz"}

%Kit{component_id: 1, sku_id: 3, quantity: 2}
%Sku{sku_id: 3, name: "Kingston 16 GB DDR4 at 3200 MHz"}
```

## Setup

First, make sure you are running the dependency services with `docker-compose`:

```shell
docker-compose up
```

Alternatively, services and required tools can be installed with [asdf](https://github.com/asdf-vm/asdf):

```shell
# Install required headers for MySQL
sudo apt-get install unzip libtinfo5 libaio1

# Install asdf plugins
asdf plugin-add mysql
asdf plugin-add grpcurl https://github.com/asdf-community/asdf-grpcurl.git
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git

# Install required tool versions on this project directory
asdf install

# Setup MySQL
mkdir -p $HOME/mysql_data
mysql_install_db --datadir=$HOME/mysql_data
mysql_secure_installation

# Setup/Run MySQL Server
mysqld -D --datadir=$HOME/mysql_data
```

Read more on [http://asdf-vm.com/](http://asdf-vm.com/) for usage information.


Dependencies are managed via `mix`. In the repo, run:

```shell
mix deps.get
```

Then run this to test the project:

```shell
mix test
```
