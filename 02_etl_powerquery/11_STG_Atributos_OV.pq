// ────────────────────────────────────────────────────────────────────
// STG_Atributos_OV
//
// Capa       : Staging  ·  carga deshabilitada
// Origen     : Referencia a 02_OV_base
// Grano      : Una fila por orden de venta
// Entrega a  : Dim_OV (Fecha_Comprometida, Sucursal, Destino)
//
// POR QUÉ EXISTE
//   Lleva los atributos comerciales del grano de línea al grano de
//   pedido, que es la unidad de análisis. Se hace en una consulta
//   aparte y no dentro de Dim_OV para que el merge posterior sea una
//   sola operación legible en vez de una agrupación anidada.
//
// DECISIONES CLAVE
//   · Agrupa con List.Max sobre campos que deberían ser constantes
//     dentro de la misma OV. Si variaran, el máximo es una elección
//     declarada y no un accidente — preferible a que Power Query elija
//     por su cuenta.
//   · Fecha_Comprometida null es lo que luego define la bandera «Sin
//     datos comerciales»: 2.567 pedidos. No se rellena, se declara.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"02_OV_base",
    #"Filas agrupadas" = Table.Group(Origen, {"Nro_Doc"}, {{"Fecha_Comprometida", each List.Max([Fecha_Comprometida]), type nullable date}, {"Sucursal", each List.Max([Sucursal]), type nullable text}, {"Destino", each List.Max([Destino]), type nullable text}})
in
    #"Filas agrupadas"
