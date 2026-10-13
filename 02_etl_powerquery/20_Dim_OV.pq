// ────────────────────────────────────────────────────────────────────
// Dim_OV  ·  la unidad de análisis del proyecto
//
// Capa       : Dimensión  ·  CARGADA al modelo
// Origen     : Referencia a 01_picking_base + merge con 5 staging
// Grano      : Una fila por orden de venta
// Filas      : 18.538
// Entrega a  : F_Linea_OV · F_Linea_Picking · Dim_Calendario · Dim_Hora
//
// POR QUÉ EXISTE
//   Es la tabla que recibe los filtros y donde vive el KPI principal.
//   El indicador es «% de pedidos que incumplen», así que la unidad de
//   análisis es el pedido — no la línea ni el picking. Ponerla como
//   DIMENSIÓN y no como tabla de hechos simplificó radicalmente todas
//   las medidas: sin esto, cada conteo habría necesitado DISTINCTCOUNT
//   sobre una tabla de detalle, con el riesgo permanente de duplicar.
//
// DECISIONES CLAVE
//   · Se construye con AGRUPAR POR, no con Elegir columnas. Las
//     dimensiones colapsan filas; los hechos las conservan. Esa
//     distinción costó 5.683 filas y 2.951.168 unidades perdidas en
//     silencio la primera vez que se confundió.
//   · LeadTime_Cal y LeadTime_Hab se traen con List.Max desde la base,
//     donde ya estaban calculadas. No se recalculan aquí: el cálculo
//     vive lo más cerca del origen posible.
//   · Pickings usa List.Count(List.Distinct([Nro_Picking])) — contar
//     valores distintos de UNA columna. La interfaz de Agrupar por no
//     ofrece esa opción: hay que escribirla a mano.
//     Table.RowCount(Table.Distinct(_)) cuenta FILAS distintas, que no
//     es lo mismo y da el total de líneas.
//   · Los cinco merge (valor, atributos, cliente, vendedor, modo de
//     entrega) APLANAN lo que de otro modo serían dimensiones colgando
//     de otra dimensión. El modelo quedó así una constelación limpia
//     en vez de un copo de nieve, sin perder ni un atributo.
//   · Cumple_SLA es una columna calculada en DAX, no en M, porque
//     compara contra SLA_Horas y emite un juicio de TRES valores:
//     Cumple · Incumple · Sin medición. La tercera categoría es
//     obligatoria — un pedido sin fecha de cierre no es un pedido
//     cumplido.
//   · Tiene_Datos_Comerciales marca los 2.567 pedidos sin fecha
//     comprometida. Se declara como bandera en vez de rellenarse: una
//     bandera es información, un cero es mentira.
//
// ⚠  PENDIENTE DE CORREGIR
//   La columna FechaHora_Fin agrega List.Max([FechaHora_GR]) en vez de
//   List.Max([FechaHora_Fin]). El nombre no corresponde al contenido y
//   queda vacía para el 68,9 % de los recojos. No afecta a los KPI
//   (LeadTime_Hab viene ya calculado de la base), pero debe corregirse
//   y hay que revisar si alguna relación inactiva con Dim_Calendario
//   cuelga de ella. Además: el grupo incluye OV_Modificada y
//   Picking_Desfasado junto a Nro_Doc. Si esos valores variaran dentro
//   de una misma OV, la OV se duplicaría y rompería la relación 1 a
//   muchos. Hoy cuadra en 18.538, pero es frágil: la llave de una
//   dimensión debería ser Nro_Doc sola.
// ────────────────────────────────────────────────────────────────────

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
