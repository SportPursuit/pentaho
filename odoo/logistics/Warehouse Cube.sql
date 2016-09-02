select
  sp.name "Picking",
  sp.state "Picking State",
  sp.type "Picking Type",
  po.name "PO",
  so.name "SO",
  sp.number_of_packages "No. Packages",
  sp.move_type "Picking Move",
  dc.name "Carrier",
  sm.location_id,
  sm.location_dest_id,
  coalesce(sm.price_unit, 0.0) "Price",
  sm.product_qty "Qty",
  pp.name_template "Product",
  coalesce(sm.product_qty * coalesce(sm.price_unit_net,0.0), 0.0) as "Move Value",
  to_char(sp.date, 'YYYY-MM-dd') "Create Date",
  extract(week from sp.date) "Create Week",
  extract(year from sp.date) "Create Year",
  extract(month from sp.date) "Create Month",
  to_char(sp.date, 'MON') "Create Month Name",
  to_char(sm.date, 'YYYY-MM-dd') "Expected/Done Date",
  extract(week from sm.date) "Expected/Done Week",
  extract(year from sm.date) "Expected/Done Year",
  extract(month from sm.date) "Expected/Done Month",
  to_char(sm.date, 'MON') "Expected/Done Month Name",
  case
    when sp.name ilike '%return%' and sp.type = 'in' then True
    else False
  end as "Is Return",
  to_char(sp.date_done, 'YYYY-MM-dd') "Picking Done Date",
  extract(week from sp.date_done) "Picking Done Week",
  extract(year from sp.date_done) "Picking Done Year",
  extract(month from sp.date_done) "Picking Done Month",
  to_char(sp.date_done, 'MON') "Picking Done Month Name",
  ss.name "Shop",
  rc.name "Destination Country",
  extract(day from sp.date_done - so.magento_created_at) "Average Shipment Time (Days)",
  ssl.name as "Source Location",
  ssl.usage as "Source Location Type",
  dsl.name as "Destination Location",
  dsl.usage as "Destination Location Type",
  sp.id as "Shipment",
  coalesce(proc.procure_method = 'make_to_order' and proc_po.bots_cross_dock = True, False) "Cross Dock"
from stock_picking sp
inner join stock_move sm on (sm.picking_id = sp.id)
left join procurement_order proc on proc.move_id = sm.id
left join purchase_order proc_po on proc.purchase_id = proc_po.id
left join product_product pp on (sm.product_id = pp.id)
left join purchase_order po on (sp.purchase_id = po.id)
left join sale_order so on (sp.sale_id = so.id)
left join delivery_carrier dc on (dc.id = sp.carrier_id)
left join sale_shop ss on (ss.id = so.shop_id)
left join res_partner rp on (rp.id = sp.partner_id)
left join res_country rc on (rc.id = rp.country_id)
left join stock_location ssl on (sm.location_id = ssl.id)
left join stock_location dsl on (sm.location_dest_id = dsl.id)
where sp.state not in ('draft', 'cancel') and sm.state not in ('draft', 'cancel')