// ────────────────────────────────────────────────────────────────────
// STG_Vendedor
//
// Capa       : Staging  ·  carga deshabilitada
// Origen     : Referencia a 01_picking_base
// Grano      : Una fila por vendedor
// Entrega a  : Dim_OV (columna Volumen_Vendedor)
//
// POR QUÉ EXISTE
//   Mismo patrón que STG_Cliente aplicado al vendedor: segmenta por
//   volumen de órdenes distintas atendidas en el período. Sirve para
//   cortar el incumplimiento por tramo de vendedor sin exponer nombres
//   propios.
//
// DECISIONES CLAVE
//   · Los cuatro tramos son criterio del analista, igual que en
//     STG_Cliente, y están declarados como supuesto.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Filas agrupadas" = Table.Group(Origen, {"Nro_Doc", "Vendedor"}, {{"Recuento", each Table.RowCount(_), Int64.Type}}),
    #"Duplicados quitados" = Table.Distinct(#"Filas agrupadas", {"Nro_Doc", "Vendedor"}),
    #"Se quito Recuento" = Table.RemoveColumns(#"Duplicados quitados",{"Recuento"}),
    #"Filas agrupadas1" = Table.Group(#"Se quito Recuento", {"Vendedor"}, {{"OVs_Periodo", each Table.RowCount(_), Int64.Type}}),
    #"Se agrego Volumen_Vendedor" = Table.AddColumn(#"Filas agrupadas1", "Volumen_Vendedor", each if [OVs_Periodo] >= 500 then "1. Alto volumen (500+)"
  else if [OVs_Periodo] >= 200 then "2. Medio (200-499)"
  else if [OVs_Periodo] >= 50  then "3. Bajo (50-199)"
  else "4. Marginal (<50)"),
    #"Se tipo Volumen_Vendedor" = Table.TransformColumnTypes(#"Se agrego Volumen_Vendedor",{{"Volumen_Vendedor", type text}})
in
    #"Se tipo Volumen_Vendedor"
