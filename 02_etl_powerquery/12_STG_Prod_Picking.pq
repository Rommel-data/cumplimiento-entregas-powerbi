// ────────────────────────────────────────────────────────────────────
// STG_Prod_Picking
//
// Capa       : Staging  ·  carga deshabilitada
// Origen     : Referencia a 01_picking_base
// Grano      : Una fila por código SAP
// Entrega a  : Dim_Producto (vía anexado)
//
// POR QUÉ EXISTE
//   Una de las dos mitades de Dim_Producto. El catálogo de productos
//   está repartido entre las dos fuentes: picking aporta la
//   descripción operativa, OV aporta marca, catálogo, unidad y
//   proveedor. Se preparan por separado y se anexan, en vez de hacer
//   un merge que dejaría fuera los SKU que solo aparecen en una
//   fuente.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Otras columnas quitadas" = Table.SelectColumns(Origen,{"Cod_Sap", "Descripcion"}),
    #"Filas agrupadas" = Table.Group(#"Otras columnas quitadas", {"Cod_Sap"}, {{"Descripcion", each List.Max([Descripcion]), type nullable text}})
in
    #"Filas agrupadas"
