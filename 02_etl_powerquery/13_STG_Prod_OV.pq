// ────────────────────────────────────────────────────────────────────
// STG_Prod_OV
//
// Capa       : Staging  ·  carga deshabilitada
// Origen     : Referencia a 02_OV_base
// Grano      : Una fila por código SAP
// Entrega a  : Dim_Producto (vía anexado)
//
// POR QUÉ EXISTE
//   La otra mitad del catálogo de productos: los atributos comerciales
//   que el extracto de picking no trae.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"02_OV_base",
    #"Otras columnas quitadas" = Table.SelectColumns(Origen,{"Cod_Sap", "Catalogo", "Marca", "Nombre_Producto", "UM", "Proveedor"}),
    #"Filas agrupadas" = Table.Group(#"Otras columnas quitadas", {"Cod_Sap"}, {{"Catalogo", each List.Max([Catalogo]), type nullable text}, {"Marca", each List.Max([Marca]), type nullable text}, {"Nombre_Producto", each List.Max([Nombre_Producto]), type nullable text}, {"UM", each List.Max([UM]), type nullable text}, {"Proveedor", each List.Max([Proveedor]), type nullable text}})
in
    #"Filas agrupadas"
