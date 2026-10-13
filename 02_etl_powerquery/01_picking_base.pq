// ────────────────────────────────────────────────────────────────────
// 01_picking_base
//
// Capa       : Base  ·  carga deshabilitada
// Origen     : Listado de Picking (Excel, tabla Tbl_Picking)
// Grano      : Una fila por línea de documento de picking
// Filas      : 108.988 crudas → 70.493 después de filtros y deduplicación
// Entrega a  : Dim_OV · Dim_Picking · F_Linea_Picking · STG_Valor_OV · STG_Prod_Picking · STG_Cliente · STG_Vendedor
//
// POR QUÉ EXISTE
//   Es la única consulta que toca el Excel de picking. Las nueve que
//   dependen de ella la REFERENCIAN, no la duplican: un arreglo aquí
//   se propaga solo. Esa decisión se tomó después de descubrir que una
//   función modificada rompía seis consultas a la vez — y que arreglar
//   la base las reparó todas de una.
//
// DECISIONES CLAVE
//   · EL ORDEN DE LOS PASOS CAMBIA EL RESULTADO. El correlativo del
//     export (Columna1 → Nro) se quita ANTES de deduplicar. Con esa
//     columna presente cada fila es única y Table.Distinct no
//     encuentra nada: devuelve 71.499 filas en vez de 70.493. La
//     primera versión deduplicaba antes y pasó inadvertido.
//   · FechaHora_OV se arma con el operador & , no con + . En M el +
//     solo acepta date + duration; date + time llena la columna entera
//     de Error. Se descubrió haciendo clic en la palabra Error para
//     leer el mensaje real, en vez de adivinar cambiando tipos.
//   · FechaHora_Fin usa la FACTURA para recojo en tienda y la GUÍA
//     para despachos. El 68,9 % de los recojos no tiene guía de
//     remisión: no es un dato faltante, es cómo cierra ese proceso.
//     Esta sola línea subió la cobertura medible del 66,9 % al 98,52
//     %.
//   · PICKING_FECHA se reduce a solo fecha con DateTime.Date. El campo
//     traía un reloj de 12 horas sin AM/PM (las horas solo iban de 1 a
//     12) y la hora es irrecuperable. Se detectó al graficar la
//     distribución horaria, no leyendo la columna.
//   · LeadTime_Habil_Horas se calcula AL FINAL de la cadena porque
//     depende de Modo_Entrega y de FechaHora_Fin. Colocarla antes dejó
//     seis consultas en rojo.
//   · Todas las columnas derivadas de campos con nulos llevan su if
//     ... = null. Flag_Urgente y Flag_Anulado dan 0 en vez de error
//     cuando no hay comentario.
//   · Las columnas de insumo (Fecha_Picking_Doc,
//     Fecha_Ult_Modificacion, Comentarios_Picking) se quitan en un
//     paso ÚNICO al final, nunca borrando el paso que las creó: eso
//     rompería todo lo que venía después.
// ────────────────────────────────────────────────────────────────────

let
    Origen = Excel.Workbook(File.Contents("C:\Users\Rommel\OneDrive\Desktop\Proyecto_Sonepar\01_Fuente\Listado de Picking - Documentos - Ene a Jul 2025.xlsx"), null, true),
    Tbl_Picking_Table = Origen{[Item="Tbl_Picking",Kind="Table"]}[Data],
    #"Filtrar solo PRI-FIS" = Table.SelectRows(Tbl_Picking_Table, each ([DOC_ALMACEN] = "PRI-FIS")),
    #"Filtrar solo OR" = Table.SelectRows(#"Filtrar solo PRI-FIS", each ([Tipo Doc] = "OR") and ([DOC_ALMACEN] = "PRI-FIS")),
    #"Renombrar columnas" = Table.TransformColumnTypes(#"Filtrar solo OR",{{"Columna1", Int64.Type}, {"PICKING_NRO", Int64.Type}, {"PICKING_FECHA", type datetime}, {"Tipo Doc", type text}, {"Forma Entrega.", type text}, {"Estado Picking", type text}, {"Nro Doc", Int64.Type}, {"Fecha Doc Origen", type date}, {"Fecha Picking", type date}, {"DOC_HORA", type time}, {"Doc_Actualiz", type date}, {"DOC_PRIORIDAD", type text}, {"RAZON_SOCIAL", type text}, {"Comentarios Picking", type text}, {"REFERENCIA", type text}, {"Cant.Solic.", Int64.Type}, {"Cant.Abierta", Int64.Type}, {"Cod.Sap", type text}, {"DESCRIPCION", type text}, {"DOC_VENTA_SOL", type number}, {"DOC_ABIERTO_SOL", type number}, {"PICKING_CANTIDAD", Int64.Type}, {"Nro GR", type text}, {"Fecha GR", type date}, {"Hora GR", type time}, {"FA_NUMERO", type text}, {"FA_CREACION", type date}, {"FA_HORA", type time}, {"DOC_VENDEDOR", type text}, {"DOC_ALMACEN", type text}}),
    #"Extraer solo PICKING_FECHA" = Table.TransformColumns(#"Renombrar columnas",{{"PICKING_FECHA", DateTime.Date, type date}}),
    #"Columnas con nombre cambiado" = Table.RenameColumns(#"Extraer solo PICKING_FECHA",{{"PICKING_FECHA", "Fecha_Creacion_Picking"}, {"PICKING_NRO", "Nro_Picking"}, {"Tipo Doc", "Tipo_Doc"}, {"Forma Entrega.", "Forma_Entrega"}, {"Estado Picking", "Estado_Picking"}, {"Nro Doc", "Nro_Doc"}, {"Fecha Doc Origen", "Fecha_Doc_Origen"}, {"DOC_HORA", "Doc_Hora"}, {"DOC_PRIORIDAD", "Doc_Prioridad"}, {"RAZON_SOCIAL", "Razon_Social"}, {"Cant.Solic.", "Cantidad_Solicitada"}, {"Cant.Abierta", "Cantidad_Abierta"}, {"Cod.Sap", "Cod_Sap"}, {"DESCRIPCION", "Descripcion"}, {"DOC_VENTA_SOL", "Doc_Venta_Sol"}, {"DOC_ABIERTO_SOL", "Doc_Abierto_Sol"}, {"PICKING_CANTIDAD", "Picking_Cantidad"}, {"Nro GR", "Nro_Gr"}, {"Fecha GR", "Fecha_Gr"}, {"Hora GR", "Hora_Gr"}, {"FA_NUMERO", "Fa_Numero"}, {"FA_CREACION", "Fa_Creacion"}, {"FA_HORA", "Fa_Hora"}, {"DOC_VENDEDOR", "Doc_Vendedor"}, {"DOC_ALMACEN", "Doc_Almacen"}}),
    #"Filtrar desde 2025" = Table.SelectRows(#"Columnas con nombre cambiado", each [Fecha_Doc_Origen] >= #date(2025, 1, 1)),
    #"Duplicados quitados" = Table.Distinct(#"Filtrar desde 2025"),
    #"Se tipo Nro_Picking, Nro_Doc" = Table.TransformColumnTypes(#"Duplicados quitados",{{"Nro_Picking", type text}, {"Nro_Doc", type text}}),
    #"Se agrego Hora_OV" = Table.AddColumn(#"Se tipo Nro_Picking, Nro_Doc", "Hora_OV", each Time.Hour([Doc_Hora])),
    #"Se agrego Minutos_Dia_OV" = Table.AddColumn(#"Se agrego Hora_OV", "Minutos_Dia_OV", each Time.Hour([Doc_Hora])*60 + Time.Minute([Doc_Hora])),
    #"Se tipo Minutos_Dia_OV, Hora_OV" = Table.TransformColumnTypes(#"Se agrego Minutos_Dia_OV",{{"Minutos_Dia_OV", Int64.Type}, {"Hora_OV", Int64.Type}}),
    #"Se agrego Bucket_Corte" = Table.AddColumn(#"Se tipo Minutos_Dia_OV, Hora_OV", "Bucket_Corte", each if [Minutos_Dia_OV] <= 630 then "1. Antes del corte manana (<=10:30)" else if [Minutos_Dia_OV] <= 690 then "2. Ventana urgencia manana (10:31-11:30)" else if [Minutos_Dia_OV] <= 990 then "3. Entre cortes (11:31-16:30)" else if [Minutos_Dia_OV] <= 1050 then "4. Ventana urgencia tarde (16:31-17:30)" else if [Minutos_Dia_OV] < 1140 then "5. Fuera de corte (17:31-19:00)" else "6. Nocturno (>19:00)"),
    #"Se agrego FechaHora_OV" = Table.AddColumn(#"Se agrego Bucket_Corte", "FechaHora_OV", each [Fecha_Doc_Origen]&[Doc_Hora]),
    #"Se tipo FechaHora_OV" = Table.TransformColumnTypes(#"Se agrego FechaHora_OV",{{"FechaHora_OV", type datetime}}),
    #"Columnas reordenadas" = Table.ReorderColumns(#"Se tipo FechaHora_OV",{"Nro_Picking", "Fecha_Creacion_Picking", "Tipo_Doc", "Forma_Entrega", "Estado_Picking", "Nro_Doc", "Fecha_Doc_Origen", "Doc_Hora", "Doc_Prioridad", "Razon_Social", "Cantidad_Solicitada", "Cantidad_Abierta", "Cod_Sap", "Descripcion", "Doc_Venta_Sol", "Doc_Abierto_Sol", "Picking_Cantidad", "Nro_Gr", "Fecha_Gr", "Hora_Gr", "Fa_Numero", "Fa_Creacion", "Fa_Hora", "Doc_Vendedor", "Doc_Almacen", "Hora_OV", "Minutos_Dia_OV", "FechaHora_OV", "Bucket_Corte"}),
    #"Se agreggo FechaHora_GR" = Table.AddColumn(#"Columnas reordenadas", "FechaHora_GR", each if([Fecha_Gr]=null or [Hora_Gr]=null) then null else [Fecha_Gr]&[Hora_Gr]),
    #"Se tipo FehcaHora_GR" = Table.TransformColumnTypes(#"Se agreggo FechaHora_GR",{{"FechaHora_GR", type datetime}}),
    #"Renombrar columnas 2" = Table.RenameColumns(#"Se tipo FehcaHora_GR",{{"Fecha_Gr", "Fecha_GR"}, {"Nro_Gr", "Nro_GR"}, {"Hora_Gr", "Hora_GR"}}),
    #"Se agrego Modo_Entrega" = Table.AddColumn(#"Renombrar columnas 2", "Modo_Entrega", each if [Forma_Entrega] = null then "Sin clasificar"
  else if Text.StartsWith([Forma_Entrega], "Recjo") then "Recojo en tienda"
  else if Text.StartsWith([Forma_Entrega], "Des-L") then "Despacho Local"
  else if Text.StartsWith([Forma_Entrega], "Des-P") then "Despacho Provincia"
  else "Sin clasificar"),
    #"Se agrego Hora_GR_Num" = Table.AddColumn(#"Se agrego Modo_Entrega", "Hora_GR_Num", each if [Hora_GR] = null then null else Time.Hour([Hora_GR])),
    #"Columnas quitada Forma_Entrega" = Table.RemoveColumns(#"Se agrego Hora_GR_Num",{"Forma_Entrega"}),
    #"Columnas con nombre cambiado1" = Table.RenameColumns(#"Columnas quitada Forma_Entrega",{{"Columna1", "Nro"}}),
    #"Se tipo Nro" = Table.TransformColumnTypes(#"Columnas con nombre cambiado1",{{"Nro", type text}}),
    #"Columnas quitadas Nro" = Table.RemoveColumns(#"Se tipo Nro",{"Nro"}),
    #"Se agrego Media_Hora_OV" = Table.AddColumn(#"Columnas quitadas Nro", "Media_Hora_OV", each Number.RoundDown([Minutos_Dia_OV] / 30) * 30),
    #"Se tipo Media_Hora_OV" = Table.TransformColumnTypes(#"Se agrego Media_Hora_OV",{{"Media_Hora_OV", Int64.Type}}),
    #"Se agrego Media_Hora_GR" = Table.AddColumn(#"Se tipo Media_Hora_OV", "Media_Hora_GR", each if [Hora_GR] = null then null
  else Number.RoundDown( ( Time.Hour([Hora_GR]) * 60 + Time.Minute([Hora_GR]) ) / 30 ) * 30),
    #"Columnas con nombre cambiado2" = Table.RenameColumns(#"Se agrego Media_Hora_GR",{{"Comentarios Picking", "Comentarios_Picking"}, {"Fecha Picking", "Fecha_Picking_Doc"}, {"Doc_Actualiz", "Fecha_Ult_Modificacion"}}),
    #"Se agrego Flag_Urgente" = Table.AddColumn(#"Columnas con nombre cambiado2", "Flag_Urgente", each if [Comentarios_Picking] = null then 0
  else if Text.Contains( Text.Upper([Comentarios_Picking]), "URGENTE" ) then 1
  else 0),
    #"Se tipo Flag_Urgente" = Table.TransformColumnTypes(#"Se agrego Flag_Urgente",{{"Flag_Urgente", Int64.Type}}),
    #"Se agrego Flag_Anulado" = Table.AddColumn(#"Se tipo Flag_Urgente", "Flag_Anulado", each if [Comentarios_Picking] = null then 0
  else if Text.Contains( Text.Upper([Comentarios_Picking]), "ANULA" ) then 1 else 0),
    #"Se tipo Flag_Anulado" = Table.TransformColumnTypes(#"Se agrego Flag_Anulado",{{"Flag_Anulado", Int64.Type}}),
    #"Se agrego OV_Modificada" = Table.AddColumn(#"Se tipo Flag_Anulado", "OV_Modificada", each [Fecha_Ult_Modificacion]>[Fecha_Doc_Origen]),
    #"Se agrego Picking_Desfasado" = Table.AddColumn(#"Se agrego OV_Modificada", "Picking_Desfasado", each [Fecha_Picking_Doc] <> [Fecha_Doc_Origen]),
    #"Se tipo Media_Hora_GR" = Table.TransformColumnTypes(#"Se agrego Picking_Desfasado",{{"Media_Hora_GR", Int64.Type}}),
    #"Columnas quitadas Fecha_Picking_Doc, Fecha_Ult_Modificacion, Comentarios" = Table.RemoveColumns(#"Se tipo Media_Hora_GR",{"Fecha_Picking_Doc", "Fecha_Ult_Modificacion", "Comentarios_Picking"}),
    #"Se agrego FechaHora_FA" = Table.AddColumn(#"Columnas quitadas Fecha_Picking_Doc, Fecha_Ult_Modificacion, Comentarios", "FechaHora_FA", each if [Fa_Creacion] = null or [Fa_Hora] = null then null
  else [Fa_Creacion] & [Fa_Hora]),
    #"Se tipo FechaHora_FA" = Table.TransformColumnTypes(#"Se agrego FechaHora_FA",{{"FechaHora_FA", type datetime}}),
    #"Se agrego FechaHora_Fin" = Table.AddColumn(#"Se tipo FechaHora_FA", "FechaHora_Fin", each if [Modo_Entrega] = "Recojo en tienda" then [FechaHora_FA]
  else if [FechaHora_GR] <> null then [FechaHora_GR]
  else [FechaHora_FA]),
    #"Se tipo FechaHora_Fin" = Table.TransformColumnTypes(#"Se agrego FechaHora_Fin",{{"FechaHora_Fin", type datetime}}),
    #"Se agrego LeadTime_Horas" = Table.AddColumn(#"Se tipo FechaHora_Fin", "LeadTime_Horas", each if [FechaHora_Fin] = null then null
  else Duration.TotalHours( [FechaHora_Fin] - [FechaHora_OV] )),
    #"Se tipo LeadTime_Horas" = Table.TransformColumnTypes(#"Se agrego LeadTime_Horas",{{"LeadTime_Horas", type number}}),
    #"Personalizada agregada" = Table.AddColumn(#"Se tipo LeadTime_Horas", "LeadTime_Habil_Horas", each if [Modo_Entrega] = "Recojo en tienda"
  then fnHorasHabiles([FechaHora_OV], [FechaHora_Fin], 480, 1110, 540, 660)
  else fnHorasHabiles([FechaHora_OV], [FechaHora_Fin], 480, 1200, 480,  840)),
    #"Se agrego LeadTime_Habil_Horas" = Table.TransformColumnTypes(#"Personalizada agregada",{{"LeadTime_Habil_Horas", type number}}),
    #"Se puso nuevo nombre Refernecia y Vendedor" = Table.RenameColumns(#"Se agrego LeadTime_Habil_Horas",{{"REFERENCIA", "Referencia"}, {"Doc_Vendedor", "Vendedor"}}),
    #"Quitar duplicados exactos" = Table.Distinct(#"Se puso nuevo nombre Refernecia y Vendedor")
in
    #"Quitar duplicados exactos"
