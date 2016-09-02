SELECT
	pr.magento_brand "Brand",
	COALESCE(so.name, sp.name) "Name",
	po.id IS NOT NULL AND (po.bots_cross_dock = TRUE) "Crossdock",
	po.minimum_planned_date "PO due by date",
	EXTRACT(DAY FROM NOW() - bspo.create_date) "Days since sent to WH"
FROM
	stock_picking sp
INNER JOIN stock_move sm
	ON sm.picking_id = sp.id
INNER JOIN product_product pr
	ON pr.id = sm.product_id
LEFT OUTER JOIN bots_stock_picking_out bspo
	ON bspo.openerp_id = sp.id
LEFT OUTER JOIN sale_order so
	ON sp.sale_id = so.id
LEFT OUTER JOIN procurement_order proc
	ON proc.move_id = sm.id
LEFT OUTER JOIN purchase_order po
	ON proc.purchase_id = po.id
WHERE
	sp.type = 'out'
AND
	sp.state = 'assigned'