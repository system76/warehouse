import EctoEnum

defenum(AreaEnum, :area, [:assembly, :receiving, :shipped, :shipping, :storage, :transit])

defenum(PayableAccountType, :payable_account_type, [:net_0_payable, :net_30_payable, :net_45_payable, :net_60_payable])

defenum(SkuKindEnum, :kind, [
  :accessory,
  :apparel_and_bags,
  :barebone,
  :cable,
  :case,
  :cooling,
  :cpu,
  :display,
  :gpu,
  :io_board,
  :motherboard,
  :networking,
  :power,
  :raid,
  :rail,
  :ram,
  :storage
])
