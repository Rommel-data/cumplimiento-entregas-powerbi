// ────────────────────────────────────────────────────────────────────
// Dim_Picking
//
// Capa       : Dimensión  ·  CARGADA al modelo
// Origen     : Referencia a 01_picking_base
// Grano      : Una fila por documento de picking
// Filas      : 21.761
// Entrega a  : F_Linea_Picking · Dim_Calendario (relación inactiva por Fecha_Creacion_Picking)
//
// POR QUÉ EXISTE
//   Describe el trabajo del almacén a su propio grano. Es la tabla que
//   permitió confirmar la hipótesis de complejidad y refutar la de
//   carga: sin un grano de picking no se puede preguntar «cuántos
//   pickings creó facturación ese día» ni «cuánto tardan los pickings
//   de 16 líneas o más».
//
// DECISIONES CLAVE
//   · SKUs usa List.Count(List.Distinct([Cod_Sap])). Es la misma
//     trampa que en Dim_OV: con Table.RowCount(Table.Distinct(_)) el
//     valor salía idéntico a Lineas, porque cuenta filas distintas y
//     no valores distintos de una columna.
//   · Tamaño_Picking convierte una variable continua (número de
//     líneas) en tres tramos. El corte en 5 y 15 no es arbitrario: se
//     probó dónde el tiempo mediano rompía el plazo de 24 h. Ahí
//     apareció el salto de 9 h a 31 h.
//   · Lineas_Urgentes y Lineas_Anuladas suman las banderas que la base
//     extrajo de un campo de texto libre. Un comentario de operario no
//     es un dato estructurado, pero buscar URGENTE y ANULA dentro de
//     él sí produce uno.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Filas agrupadas" = Table.Group(
    Origen,
    {"Nro_Picking", "Fecha_Creacion_Picking", "Estado_Picking"},
    {
      {"Lineas",          each Table.RowCount(_),                    Int64.Type},
      {"Unidades",        each List.Sum([Picking_Cantidad]),         Int64.Type},
      {"SKUs",            each List.Count(List.Distinct([Cod_Sap])), Int64.Type},
      {"Lineas_Urgentes", each List.Sum([Flag_Urgente]),             Int64.Type},
      {"Lineas_Anuladas", each List.Sum([Flag_Anulado]),             Int64.Type}
    }
),
    #"Personalizada agregada" = Table.AddColumn(#"Filas agrupadas", "Tamaño_Picking", each if [Lineas] <= 5 then "1. Simple (1-5 lineas)" else if [Lineas] <= 15 then "2. Mediano (6-15)" else "3. Complejo (16+)")
in
    #"Personalizada agregada"
