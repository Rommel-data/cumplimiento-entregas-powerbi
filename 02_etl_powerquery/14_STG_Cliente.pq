// ────────────────────────────────────────────────────────────────────
// STG_Cliente
//
// Capa       : Staging  ·  carga deshabilitada
// Origen     : Referencia a 01_picking_base
// Grano      : Una fila por cliente
// Entrega a  : Dim_OV (columna Frecuencia_compra)
//
// POR QUÉ EXISTE
//   Construye una segmentación de clientes POR COMPORTAMIENTO, porque
//   la clasificación comercial oficial no existe en la fuente. Es un
//   PROXY y está declarado como tal en las limitaciones del proyecto:
//   no debe usarse para decisiones comerciales por cliente.
//
// DECISIONES CLAVE
//   · Cuenta ÓRDENES DISTINTAS por cliente, no filas. Contar filas
//     habría premiado a los clientes que piden muchas líneas por
//     pedido en vez de a los que piden seguido. El patrón es: agrupar
//     por (OV, cliente) para colapsar las líneas, y después agrupar
//     por cliente para contar.
//   · Los cinco tramos de frecuencia los definió el analista, no la
//     empresa. Un umbral inventado que se presenta como regla de
//     negocio es una mentira silenciosa; por eso va en el documento de
//     reglas marcado como supuesto.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Filas agrupadas" = Table.Group(Origen, {"Nro_Doc", "Razon_Social"}, {{"Recuento", each Table.RowCount(_), Int64.Type}}),
    #"Duplicados quitados" = Table.Distinct(#"Filas agrupadas"),
    #"Se quito Recuento" = Table.RemoveColumns(#"Duplicados quitados",{"Recuento"}),
    #"Filas agrupadas1" = Table.Group(#"Se quito Recuento", {"Razon_Social"}, {{"OVs_Periodo", each Table.RowCount(_), Int64.Type}}),
    #"Se agrego personalizada Frecuencia_compra" = Table.AddColumn(#"Filas agrupadas1", "Frecuencia_compra", each if [OVs_Periodo] >=100 then "1. Muy frecuente (+100)"
else if [OVs_Periodo] >=30 then "2. Frecuente (30-99)"
else if [OVs_Periodo] >=10 then "3. Regular (10-29)"
else if [OVs_Periodo] >=3 then "4. Ocasional (3-9)"
else "5. Esporadico (1-2)"),
    #"Se tipo Frecuencia_compra" = Table.TransformColumnTypes(#"Se agrego personalizada Frecuencia_compra",{{"Frecuencia_compra", type text}})
in
    #"Se tipo Frecuencia_compra"
