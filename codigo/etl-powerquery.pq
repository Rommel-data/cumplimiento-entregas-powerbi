// ═══════════════════════════════════════════════════════════════════════════
// PROCESO ETL COMPLETO  ·  Power Query (lenguaje M)
// Proyecto: Cumplimiento de plazos de entrega — Centro de Distribución
//
// 18 consultas, en orden de dependencia. Nueve entran al modelo; las demás
// son andamiaje con la carga deshabilitada.
//
// Para reutilizar una consulta: copiar su bloque y pegarlo en
// Power Query → Nueva consulta → Consulta en blanco → Editor avanzado.
//
// El razonamiento detrás de cada decisión está en el README del repositorio.
// ═══════════════════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────────────────────────────
//  1.  00_fnHorasHabiles
//     Función parametrizada: horas hábiles entre dos fechas, según el horario real de cada modalidad.
// ──────────────────────────────────────────────────────────────────────

(Inicio as nullable datetime, Fin as nullable datetime,
 AbreLV as number, CierraLV as number,
 AbreSab as number, CierraSab as number) as nullable number =>
let
    Resultado =
        if Inicio = null or Fin = null or Fin < Inicio then null
        else
        let
            FechaIni = DateTime.Date(Inicio),
            FechaFin = DateTime.Date(Fin),
            Dias = List.Dates(
                     FechaIni,
                     Duration.Days(FechaFin - FechaIni) + 1,
                     #duration(1,0,0,0)
                   ),
            HorasPorDia = List.Transform(Dias, each
                let
                    Dia = _,
                    Dow = Date.DayOfWeek(Dia, Day.Monday),
                    Abre   = if Dow <= 4 then AbreLV   else if Dow = 5 then AbreSab   else null,
                    Cierra = if Dow <= 4 then CierraLV else if Dow = 5 then CierraSab else null,
                    Horas =
                        if Abre = null then 0
                        else
                        let
                            AbreDT   = DateTime.From(Dia) + #duration(0,0,Abre,0),
                            CierraDT = DateTime.From(Dia) + #duration(0,0,Cierra,0),
                            Desde = List.Max({Inicio, AbreDT}),
                            Hasta = List.Min({Fin, CierraDT})
                        in
                            if Hasta > Desde
                            then Duration.TotalHours(Hasta - Desde)
                            else 0
                in
                    Horas
            )
        in
            List.Sum(HorasPorDia)
in
    Resultado

// ──────────────────────────────────────────────────────────────────────
//  2.  01_picking_base
//     Base del lado operativo. Lee el Excel de picking, filtra el universo, deduplica y deriva todas las columnas de tiempo. 70.493 filas. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────────────
//  3.  02_ov_base
//     Base del lado comercial. Aporta la acción de abastecimiento, el stock por almacén y los atributos del producto. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = Excel.Workbook(File.Contents("C:\Users\Rommel\OneDrive\Desktop\Proyecto_Sonepar\01_Fuente\Listado de OV.xlsx"), null, true),
    Sheet1_Sheet = Origen{[Item="Sheet1",Kind="Sheet"]}[Data],
    #"Encabezados promovidos" = Table.PromoteHeaders(Sheet1_Sheet, [PromoteAllScalars=true]),
    #"Tipo cambiado" = Table.TransformColumnTypes(#"Encabezados promovidos",{{"#", Int64.Type}, {"Numero_OV", Int64.Type}, {"Sucursal", type text}, {"Cliente", type text}, {"F.Emision", type date}, {"Dia", type text}, {"Mes", type text}, {"Catalogo", type text}, {"Marca", type text}, {"CodigoSAP", type text}, {"Nombre Producto", type text}, {"UM", type text}, {"Cantidad", Int64.Type}, {"Prioridad", type text}, {"Accion", type text}, {"Prod.Stock", type text}, {"Almacen", type text}, {"Stock", Int64.Type}, {"Precio", type number}, {"Total", type number}, {"Proveedor", type text}, {"Vendedor", type text}, {"Stock Disp. Alm Facturacion", Int64.Type}, {"Stock CD (PRI FIS)", Int64.Type}, {"Fecha_Entrega", type date}, {"Guia", type text}, {"Fecha GR", type date}, {"Factura", type text}, {"Fecha FT", type date}, {"Forma de Entrega", type text}, {"Destino", type text}, {"Destino de Factura", type text}}),
    #"Filtrar solo PRI-FIS" = Table.SelectRows(#"Tipo cambiado", each ([Almacen] = "PRI-FIS")),
    #"Columnas quitadas" = Table.RemoveColumns(#"Filtrar solo PRI-FIS",{"#"}),
    #"Tipo cambiado1" = Table.TransformColumnTypes(#"Columnas quitadas",{{"Numero_OV", type text}}),
    #"Columnas quitadas1" = Table.RemoveColumns(#"Tipo cambiado1",{"Cliente", "F.Emision", "Dia", "Mes", "Prioridad", "Vendedor", "Guia", "Fecha GR", "Factura", "Fecha FT", "Forma de Entrega", "Almacen"}),
    #"Cambiar nombre de los campos" = Table.RenameColumns(#"Columnas quitadas1",{{"Numero_OV", "Nro_Doc"}, {"CodigoSAP", "Cod_Sap"}, {"Fecha_Entrega", "Fecha_Comprometida"}, {"Nombre Producto", "Nombre_Producto"}, {"Prod.Stock", "Prod_Stock"}, {"Stock Disp. Alm Facturacion", "Stock_Alm_Facturacion"}, {"Stock CD (PRI FIS)", "Stock_CD"}, {"Destino de Factura", "Destino_Factura"}}),
    #"Tipar columna de Fecha Comprometida" = Table.TransformColumnTypes(#"Cambiar nombre de los campos", {{"Fecha_Comprometida", type date}}, "es-PE"),
    #"Duplicados quitados" = Table.Distinct(#"Tipar columna de Fecha Comprometida")
in
    #"Duplicados quitados"

// ──────────────────────────────────────────────────────────────────────
//  4.  10_STG_Valor_OV
//     Resuelve el importe no aditivo con dos agrupaciones encadenadas. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Quitar repeticion por OV y SKU" = Table.Group(Origen, {"Nro_Doc", "Cod_Sap"}, {{"Valor_Linea", each List.Max([Doc_Venta_Sol]), type nullable number}}),
    #"Sumar valor por OV" = Table.Group(#"Quitar repeticion por OV y SKU", {"Nro_Doc"}, {{"Valor_OV", each List.Sum([Valor_Linea]), type nullable number}})
in
    #"Sumar valor por OV"

// ──────────────────────────────────────────────────────────────────────
//  5.  11_STG_Atributos_OV
//     Lleva los atributos comerciales al grano de pedido. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = #"02_OV_base",
    #"Filas agrupadas" = Table.Group(Origen, {"Nro_Doc"}, {{"Fecha_Comprometida", each List.Max([Fecha_Comprometida]), type nullable date}, {"Sucursal", each List.Max([Sucursal]), type nullable text}, {"Destino", each List.Max([Destino]), type nullable text}})
in
    #"Filas agrupadas"

// ──────────────────────────────────────────────────────────────────────
//  6.  12_STG_Prod_Picking
//     Mitad operativa del catálogo de productos. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Otras columnas quitadas" = Table.SelectColumns(Origen,{"Cod_Sap", "Descripcion"}),
    #"Filas agrupadas" = Table.Group(#"Otras columnas quitadas", {"Cod_Sap"}, {{"Descripcion", each List.Max([Descripcion]), type nullable text}})
in
    #"Filas agrupadas"

// ──────────────────────────────────────────────────────────────────────
//  7.  13_STG_Prod_OV
//     Mitad comercial del catálogo de productos. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = #"02_OV_base",
    #"Otras columnas quitadas" = Table.SelectColumns(Origen,{"Cod_Sap", "Catalogo", "Marca", "Nombre_Producto", "UM", "Proveedor"}),
    #"Filas agrupadas" = Table.Group(#"Otras columnas quitadas", {"Cod_Sap"}, {{"Catalogo", each List.Max([Catalogo]), type nullable text}, {"Marca", each List.Max([Marca]), type nullable text}, {"Nombre_Producto", each List.Max([Nombre_Producto]), type nullable text}, {"UM", each List.Max([UM]), type nullable text}, {"Proveedor", each List.Max([Proveedor]), type nullable text}})
in
    #"Filas agrupadas"

// ──────────────────────────────────────────────────────────────────────
//  8.  14_STG_Cliente
//     Segmenta clientes por frecuencia de compra. Proxy declarado. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────────────
//  9.  15_STG_Vendedor
//     Segmenta vendedores por volumen de órdenes. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────────────
// 10.  16_STG_ModoEntrega
//     Tabla de parámetros: el plazo comprometido de cada modalidad. Carga deshabilitada.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("pcwxD4IwEIbhv3LpDLEgAzI7ODAQSVwahuOo8UzpmZb4+60aTYwjw/cO3/AYo46W5CpgPSxs/YQqU2XaAUd2MEtcAk4S0tPmJ9B1o3Ve1M1WwwZ6HEHvXk+RqobMqL2NN6SLQCuE7olVXw3djGT9j1Xq1I/11qs/qwtyZ0+M67yePZDDyGcmDCus4QE=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Modo_Entrega = _t, SLA_Horas = _t, Tipo_Reloj = _t, Ventana_Operativa = _t]),
    #"Tipo cambiado" = Table.TransformColumnTypes(Origen,{{"Modo_Entrega", type text}, {"SLA_Horas", Int64.Type}, {"Tipo_Reloj", type text}, {"Ventana_Operativa", type text}})
in
    #"Tipo cambiado"

// ──────────────────────────────────────────────────────────────────────
// 11.  20_Dim_OV
//     LA UNIDAD DE ANÁLISIS. 18.538 pedidos. Cinco merge que aplanan el modelo.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = #"01_picking_base",
    #"Filas agrupadas" = Table.Group(Origen, {"Nro_Doc", "OV_Modificada", "Picking_Desfasado"}, {{"Fecha_OV", each List.Min([Fecha_Doc_Origen]), type nullable date}, {"Franja_Ingreso", each List.Max([Bucket_Corte]), type nullable text}, {"FechaHora_OV", each List.Min([FechaHora_OV]), type nullable datetime}, {"Hora_OV", each List.Min([Hora_OV]), type nullable number}, {"Media_Hora_OV", each List.Min([Media_Hora_OV]), type nullable number}, {"Modo_Entrega", each List.Max([Modo_Entrega]), type nullable text}, {"Vendedor", each List.Max([Vendedor]), type nullable text}, {"Cliente", each List.Max([Razon_Social]), type nullable text}, {"Prioridad", each List.Max([Doc_Prioridad]), type nullable text}, {"FechaHora_Fin", each List.Max([FechaHora_GR]), type nullable datetime}, {"Media_Hora_Fin", each List.Max([Media_Hora_GR]), type nullable number}, {"LeadTime_Cal", each List.Max([LeadTime_Horas]), type nullable number}, {"LeadTime_Hab", each List.Max([LeadTime_Habil_Horas]), type nullable number}, {"Pickings", each List.Count(List.Distinct([Nro_Picking])), Int64.Type}, {"Lineas", each Table.RowCount(_), Int64.Type}, {"Lineas_Urgentes", each List.Sum([Flag_Urgente]), type nullable number}, {"Lineas_Anuladas", each List.Sum([Flag_Anulado]), type nullable number}}),
    #"Se tipo los datos" = Table.TransformColumnTypes(#"Filas agrupadas",{{"Lineas_Urgentes", Int64.Type}, {"Lineas_Anuladas", Int64.Type}, {"Media_Hora_OV", Int64.Type}, {"Hora_OV", Int64.Type}, {"Media_Hora_Fin", Int64.Type}}),
    #"Se agrego columna Es_Urgente" = Table.AddColumn(#"Se tipo los datos", "Es_Urgente", each if [Lineas_Urgentes] > 0 then "Urgente" else "Sin marca"),
    #"Se agrego columna Es_Anulado" = Table.AddColumn(#"Se agrego columna Es_Urgente", "Es_Anulado", each if [Lineas_Anuladas] > 0 then "Anulado" else "Vigente"),
    #"Se tipo Es_Urgente, Es_Anulado" = Table.TransformColumnTypes(#"Se agrego columna Es_Anulado",{{"Es_Urgente", type text}, {"Es_Anulado", type text}}),
    #"Combinar con STG_Valor_OV" = Table.NestedJoin(#"Se tipo Es_Urgente, Es_Anulado", {"Nro_Doc"}, STG_Valor_OV, {"Nro_Doc"}, "STG_Valor_OV", JoinKind.LeftOuter),
    #"Expandir Valor_OV" = Table.ExpandTableColumn(#"Combinar con STG_Valor_OV", "STG_Valor_OV", {"Valor_OV"}, {"Valor_OV"}),
    #"Tipo cambiado" = Table.TransformColumnTypes(#"Expandir Valor_OV",{{"Valor_OV", Currency.Type}}),
    #"Combinar con STG_Atributos_OV" = Table.NestedJoin(#"Tipo cambiado", {"Nro_Doc"}, STG_Atributos_OV, {"Nro_Doc"}, "STG_Atributos_OV", JoinKind.LeftOuter),
    #"Expandir atributos comerciales" = Table.ExpandTableColumn(#"Combinar con STG_Atributos_OV", "STG_Atributos_OV", {"Fecha_Comprometida", "Sucursal", "Destino"}, {"Fecha_Comprometida", "Sucursal", "Destino"}),
    #"Se agrego Tiene_Datos_Comcerciales" = Table.AddColumn(#"Expandir atributos comerciales", "Tiene_Datos_Comerciales", each if [Fecha_Comprometida] = null then "Sin datos comerciales" else "Con datos comerciales"),
    #"Se tipo Tiene_Datos_Comerciales" = Table.TransformColumnTypes(#"Se agrego Tiene_Datos_Comcerciales",{{"Tiene_Datos_Comerciales", type text}}),
    #"Combinar con Dim_Cliente" = Table.NestedJoin(#"Se tipo Tiene_Datos_Comerciales", {"Cliente"}, STG_Cliente, {"Razon_Social"}, "Dim_Cliente", JoinKind.LeftOuter),
    #"Expandir Frecuencia_Compra" = Table.ExpandTableColumn(#"Combinar con Dim_Cliente", "Dim_Cliente", {"Frecuencia_compra"}, {"Frecuencia_compra"}),
    #"Combinar con Dim_Vendedor" = Table.NestedJoin(#"Expandir Frecuencia_Compra", {"Vendedor"}, STG_Vendedor, {"Vendedor"}, "Dim_Vendedor", JoinKind.LeftOuter),
    #"Expandir Volumen_Vendedor" = Table.ExpandTableColumn(#"Combinar con Dim_Vendedor", "Dim_Vendedor", {"Volumen_Vendedor"}, {"Volumen_Vendedor"}),
    #"Combinar con Dim_ModoEntrega" = Table.NestedJoin(#"Expandir Volumen_Vendedor", {"Modo_Entrega"}, STG_ModoEntrega, {"Modo_Entrega"}, "Dim_ModoEntrega", JoinKind.LeftOuter),
    #"Expandir SLA y Tipo_Reloj" = Table.ExpandTableColumn(#"Combinar con Dim_ModoEntrega", "Dim_ModoEntrega", {"SLA_Horas", "Tipo_Reloj"}, {"SLA_Horas", "Tipo_Reloj"})
in
    #"Expandir SLA y Tipo_Reloj"

// ──────────────────────────────────────────────────────────────────────
// 12.  21_Dim_Picking
//     21.761 pickings, con el tramo de complejidad.
// ──────────────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────────────
// 13.  22_Dim_Producto
//     Dimensión conformada: sirve a las dos tablas de hechos.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = STG_Prod_Picking,
    #"Consulta anexada" = Table.Combine({Origen, STG_Prod_OV}),
    #"Filas agrupadas" = Table.Group(#"Consulta anexada", {"Cod_Sap"}, {{"Descripcion", each List.Max([Descripcion]), type nullable text}, {"Catalogo", each List.Max([Catalogo]), type nullable text}, {"Marca", each List.Max([Marca]), type nullable text}, {"Nombre_Producto", each List.Max([Nombre_Producto]), type nullable text}, {"UM", each List.Max([UM]), type nullable text}, {"Proveedor", each List.Max([Proveedor]), type nullable text}}),
    #"Se agrego Nombre_Producto_Final" = Table.AddColumn(#"Filas agrupadas", "Nombre_Producto_Final", each if [Descripcion] <> null then [Descripcion]
  else if [Nombre_Producto] <> null then [Nombre_Producto]
  else "Sin descripcion"),
    #"Se tipo a Nombre_Producto_Final" = Table.TransformColumnTypes(#"Se agrego Nombre_Producto_Final",{{"Nombre_Producto_Final", type text}}),
    #"Se quito Descripcion" = Table.RemoveColumns(#"Se tipo a Nombre_Producto_Final",{"Descripcion"}),
    #"Se tipo Nombre_Producto_Final" = Table.TransformColumnTypes(#"Se quito Descripcion",{{"Nombre_Producto_Final", type text}}),
    #"Se quito Nombre_producto" = Table.RemoveColumns(#"Se tipo Nombre_Producto_Final",{"Nombre_Producto"}),
    #"Se cambio el nombre a Producto" = Table.RenameColumns(#"Se quito Nombre_producto",{{"Nombre_Producto_Final", "Producto"}}),
    #"Columnas reordenadas" = Table.ReorderColumns(#"Se cambio el nombre a Producto",{"Cod_Sap", "Producto", "Catalogo", "Marca", "UM", "Proveedor"}),
    #"Se agrego columna Familia_Producto" = Table.AddColumn(#"Columnas reordenadas", "Familia_Producto", each let T = Text.Upper([Producto]) in
  if Text.StartsWith(T, "CONDUCTOR") then "1. Cable y conductor"
  else if Text.StartsWith(T, "LUMINARIA") or Text.StartsWith(T, "LAMPARA") or Text.StartsWith(T, "REFLECTOR") then "2. Iluminacion"
  else if Text.StartsWith(T, "INTERRUPTOR") or Text.StartsWith(T, "CONTACTOR") or Text.StartsWith(T, "RELE") or Text.StartsWith(T, "PULSADOR") then "3. Proteccion y maniobra"
  else if Text.StartsWith(T, "TERMINAL") or Text.StartsWith(T, "CONECTOR") or Text.StartsWith(T, "BORNERA") or Text.StartsWith(T, "ENCHUFE") or Text.StartsWith(T, "TOMA") or Text.StartsWith(T, "DADO") then "4. Conexion y terminales"
  else if Text.StartsWith(T, "TUBO") or Text.StartsWith(T, "TUBERIA") or Text.StartsWith(T, "CAJA") or Text.StartsWith(T, "UNION") or Text.StartsWith(T, "CANALETA") then "5. Canalizacion"
  else if Text.StartsWith(T, "TABLERO") then "6. Tablero"
  else if Text.StartsWith(T, "CINTA") or Text.StartsWith(T, "ATADOR") or Text.StartsWith(T, "PLACA") then "7. Accesorios"
  else "8. Otros"),
    #"Se tipo a Familia_Producto" = Table.TransformColumnTypes(#"Se agrego columna Familia_Producto",{{"Familia_Producto", type text}})
in
    #"Se tipo a Familia_Producto"

// ──────────────────────────────────────────────────────────────────────
// 14.  30_F_Linea_OV
//     Hechos comerciales. Contiene Accion, la columna que explicó el problema.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = #"02_OV_base",
    #"Dejar llave y métricas" = Table.SelectColumns(Origen,{"Nro_Doc", "Cod_Sap", "Accion", "Prod_Stock", "Cantidad", "Stock", "Stock_Alm_Facturacion", "Stock_CD", "Precio", "Total"})
in
    #"Dejar llave y métricas"

// ──────────────────────────────────────────────────────────────────────
// 15.  31_F_Linea_Picking
//     Hechos operativos. 70.493 filas, idéntico a la base.
// ──────────────────────────────────────────────────────────────────────

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

// ──────────────────────────────────────────────────────────────────────
// 16.  40_Doc_Reglas_Negocio
//     Cada regla con su fuente: documentada, supuesta o pendiente.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("rdLBSsRADAbgVwkFbyt0XfXgTdrjKuLiaekhnWbpLDNNyUz3HXyMgi/gM/RNfBIzu70KRb0Nk/wfCWS/z3bbR3glw0cG6iBa6hrMVtkNtCwYoJ3G2joK+vUibKixXlsiB+hREOScDFCU2lCyGbwWseGsWl3okkKPpmXYskGX4NtlcjMHl9iaP9nOWPw/v2CJBB6nT+wSu84fNvlfqIjSUILufw29+VrQQSA/jQcWhhNdzK/3D1jfXemrEBtJLCvlQCd3NsQ0/m7oBwrxB2cafY0yQ5t8MfREMQ0NOmbv5lW05zmlDraz50u6TsvqVaUqZVX1DQ==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Regla = _t, Valor = _t, Fuente = _t, Tipo = _t])
in
    Origen

// ──────────────────────────────────────────────────────────────────────
// 17.  41_Doc_Datos_Faltantes
//     Qué dato falta, para qué serviría y quién lo tiene.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("TZDNTsIxEMRfZdLEGxcIJt4l0YNGEi4mwGEpC1TbbtMPE3gjD558BF7M/RdJOPQy/e3M7C6XZsH7wLEKrATO1pHHlj2sd6qyGZkZ71xkFAeVk6eTgIsymEwhmD7gIJmKgo9XA7MeLc2ci+CIL/FN/ZEkI2XZNltF2RcCh5S5ENrwIlrY5J6N8WiCKpE9bbvvK3GpWYYvyvX8Y5uX0jOeNXmQvdtwJuvOv7GXT85+urjX2QUnypRVDf/sjmxtV/jYTX0ge/6OA+5K5UAX95nUG88bak6lW2JlDnRE1qadWxmQajvylSLekTgXiVRWRofeUq+oe13cX7kSdpLDZWnbQvIuDEeXXiQiDEQUFEZqrMxHO+01WMvcj3Gn1BNnjnpxs17/AQ==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Dato faltante" = _t, #"Para qué serviría" = _t, #"Quién lo tiene" = _t])
in
    Origen

// ──────────────────────────────────────────────────────────────────────
// 18.  42__Medidas
//     Tabla vacía que aloja las 45 medidas del modelo.
// ──────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i44FAA==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Columna1 = _t]),
    #"Tipo cambiado" = Table.TransformColumnTypes(Origen,{{"Columna1", type text}}),
    #"Columnas quitadas" = Table.RemoveColumns(#"Tipo cambiado",{"Columna1"})
in
    #"Columnas quitadas"

