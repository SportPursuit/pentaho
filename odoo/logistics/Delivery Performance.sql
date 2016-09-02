WITH po_pickings AS (
  SELECT
    COUNT(sp.purchase_id) OVER (PARTITION BY sp.purchase_id ORDER BY sp.date_done) "number",
    sp.date_done,
    sp.purchase_id,
    sp.id "picking_id"
  FROM stock_picking sp
  WHERE sp.state = 'done'
  AND sp.purchase_id IS NOT NULL
  ORDER BY sp.purchase_id, sp.id
),
po_last_picking AS (
  SELECT
    MAX(sp.date_done) "date_done",
    sp.purchase_id
  FROM stock_picking sp
  WHERE sp.purchase_id IS NOT NULL
  GROUP BY sp.purchase_id
),
po_units AS (
  SELECT
    SUM(pol.product_qty) "product_qty",
    COUNT(DISTINCT pol.product_id) "unique_skus",
    pol.order_id "purchase_id"
  FROM purchase_order_line pol
  GROUP BY pol.order_id
  ORDER BY pol.order_id
),
po_received_units AS (
  SELECT
    SUM(sm.product_qty) "product_qty",
    sp.purchase_id
  FROM stock_picking sp
  INNER JOIN stock_move sm
    ON sm.picking_id = sp.id
  WHERE sp.purchase_id IS NOT NULL
  AND sm.state = 'done'
  GROUP BY sp.purchase_id
  ORDER BY sp.purchase_id
),
sp_received_units AS (
  SELECT
    SUM(sm.product_qty) "product_qty",
    sp.id "picking_id"
  FROM stock_picking sp
  INNER JOIN stock_move sm
    ON sm.picking_id = sp.id
  WHERE sp.purchase_id IS NOT NULL
  AND sm.state = 'done'
  GROUP BY sp.id
  ORDER BY sp.id
)
SELECT
po.name "PO Number",
rp.name "Supplier",
rp_parent.name "Supplier Parent",
rp_owner.name "Owner",
COALESCE(rp.leadtime_supplier, 0) "Supplier Leadtime",
po.bots_cross_dock "Cross Dock",
po.date_approve "Date Created",
po.date_order "Order Date",
po.sp_dropship "Dropshipped",
po_pickings.date_done "Date First Received",
ROUND(CAST(EXTRACT(day FROM po_pickings.date_done - po.date_approve) + (EXTRACT(hour FROM po_pickings.date_done - po.date_approve) / 24) as numeric), 2) "Days Until First Delivery",
ROUND(CAST(EXTRACT(day FROM po_last_picking.date_done - po.date_approve) + (EXTRACT(hour FROM po_last_picking.date_done - po.date_approve) / 24) as numeric), 2) "Days Until Received/Closed",
po_units.product_qty "Number Ordered",
COALESCE(po_received_units.product_qty, 0.0) "Number Received",
rc.name "Country of Origin",
rp_buyer.name "Buyer",
po_units.unique_skus "Number of SKUs",
apt.name "Proforma",
ROUND((COALESCE(sp_received_units.product_qty, 0.0) /
    po_units.product_qty), 4) "Percent Delivered on First Delivery"
FROM purchase_order po
INNER JOIN res_partner rp
  ON rp.id = po.partner_id
LEFT OUTER JOIN res_partner rp_parent
  ON rp.parent_id = rp_parent.id
LEFT OUTER JOIN res_users ru_owner
  ON po.owner = ru_owner.id
LEFT OUTER JOIN res_partner rp_owner
  ON rp_owner.id = ru_owner.partner_id
LEFT OUTER JOIN res_country rc
  ON rc.id = rp.country_id
LEFT OUTER JOIN res_users ru_buyer
  ON po.validator = ru_buyer.id
LEFT OUTER JOIN res_partner rp_buyer
  ON rp_buyer.id = ru_buyer.partner_id
LEFT OUTER JOIN account_payment_term apt
  ON apt.id = po.payment_term_id
LEFT OUTER JOIN po_pickings
  ON po_pickings.purchase_id = po.id
  AND po_pickings.number = 1
LEFT OUTER JOIN po_last_picking
  ON po_last_picking.purchase_id = po.id
LEFT OUTER JOIN po_units
  ON po_units.purchase_id = po.id
LEFT OUTER JOIN po_received_units
  ON po_received_units.purchase_id = po.id
LEFT OUTER JOIN sp_received_units
  ON sp_received_units.picking_id = po_pickings.picking_id
WHERE po.shipped = TRUE