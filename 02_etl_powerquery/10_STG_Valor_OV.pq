// ────────────────────────────────────────────────────────────────────
// STG_Valor_OV
//
// Capa       : Staging  ·  carga deshabilitada
// Origen     : Referencia a 01_picking_base
// Grano      : Una fila por orden de venta
// Filas      : 18.538
// Entrega a  : Dim_OV (columna Valor_OV)
//
// POR QUÉ EXISTE
//   Resuelve la trampa más costosa del proyecto: Doc_Venta_Sol NO es
//   aditivo al nivel de la tabla. El importe viene repetido en cada
//   línea del detalle porque es un dato de cabecera alojado en el
//   detalle. Sumarlo directamente daba S/ 116,75 millones contra S/
//   82,23 millones reales: un 42 % de inflación.
//
// DECISIONES CLAVE
//   · Son DOS agrupaciones encadenadas, no una. La primera colapsa la
//     repetición por OV y SKU con List.Max (toma el valor una sola
//     vez); la segunda suma esos valores únicos por OV. Hacerlo en un
//     solo paso con List.Sum habría sumado la repetición otra vez.
//   · Se usa List.Max y no List.First: List.First depende del orden de
//     las filas, que no está garantizado tras una deduplicación.
//   · La detección fue comparar la suma cruda contra la suma por orden
//     distinta. La señal de un campo no aditivo es siempre la misma:
//     un importe idéntico repetido dentro de la misma entidad.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Quitar repeticion por OV y SKU" = Table.Group(Origen, {"Nro_Doc", "Cod_Sap"}, {{"Valor_Linea", each List.Max([Doc_Venta_Sol]), type nullable number}}),
    #"Sumar valor por OV" = Table.Group(#"Quitar repeticion por OV y SKU", {"Nro_Doc"}, {{"Valor_OV", each List.Sum([Valor_Linea]), type nullable number}})
in
    #"Sumar valor por OV"
