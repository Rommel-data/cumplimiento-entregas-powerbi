// ────────────────────────────────────────────────────────────────────
// F_Linea_Picking
//
// Capa       : Hechos  ·  CARGADA al modelo
// Origen     : Referencia a 01_picking_base
// Grano      : Una fila por línea de documento de picking
// Filas      : 70.493  —  idéntico a la base, por definición
// Entrega a  : Dim_OV · Dim_Picking · Dim_Producto
//
// POR QUÉ EXISTE
//   La segunda tabla de hechos del modelo. Junto con F_Linea_OV es lo
//   que convierte el esquema en una CONSTELACIÓN: dos procesos de
//   negocio con granos distintos (la línea comercial y la línea
//   operativa) compartiendo las mismas dimensiones conformadas.
//
// DECISIONES CLAVE
//   · AQUÍ ESTUVO EL ERROR MÁS CARO DEL PROYECTO. La primera versión
//     usó Agrupar por en lugar de Elegir columnas: 64.810 filas en vez
//     de 70.493, y 2.951.168 unidades menos. No dio ningún error —
//     simplemente faltaban datos. Se detectó comparando el conteo
//     contra la base, que es exactamente para lo que existen los
//     números de control.
//   · La regla que salió de ahí: dimensión → Agrupar por, hechos →
//     Elegir columnas. En una tabla de hechos el conteo de filas nunca
//     cambia al reducir columnas.
//   · El tipado explícito al final evita que Power BI infiera Nro_Doc
//     como número y le ponga el símbolo de sumatoria. Las llaves son
//     texto, aunque parezcan números: la suma de identificadores no
//     significa nada.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Dejar llaves y metricas" = Table.SelectColumns(
        Origen,
        {"Nro_Doc", "Nro_Picking", "Cod_Sap",
         "Cantidad_Solicitada", "Cantidad_Abierta", "Picking_Cantidad"}
    ),
    #"Tipar columnas" = Table.TransformColumnTypes(
        #"Dejar llaves y metricas",
        {{"Nro_Doc", type text},
         {"Nro_Picking", type text},
         {"Cod_Sap", type text},
         {"Cantidad_Solicitada", type number},
         {"Cantidad_Abierta", Int64.Type},
         {"Picking_Cantidad", Int64.Type}}
    )
in
    #"Tipar columnas"
