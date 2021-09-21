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

This micro service works very closely with (and is dependent on)
[the Assembly service](https://github.com/system76/assembly). The assembly
service is responsible for tracking build details. They have a relationship like
so:

```
Assembly <------------------------------------------------------------ Warehouse

         This is a gRPC request from Assembly to Warehouse to
         determine the `Warehouse.Schema.Component` quantity
         available. This is used to determine if a build has all of
         the needed parts in stock to build. A similar RabbitMQ
         message is broadcasted when that quantity changes.

Assembly ------------------------------------------------------------> Warehouse

         This is a gRPC request from Warehouse to Assembly to
         determine the demand of `Warehouse.Schema.Component`. This
         allows Warehouse to determine the back order status of a
         `Warehouse.Schema.Sku` and the quantity we need to
         order.
```
