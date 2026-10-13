// ────────────────────────────────────────────────────────────────────
// 02_OV_base
//
// Capa       : Base  ·  carga deshabilitada
// Origen     : Listado de OV (Excel, hoja Sheet1)
// Grano      : Una fila por línea de orden de venta
// Filas      : 161.715 crudas → filtradas a PRI-FIS y deduplicadas
// Entrega a  : F_Linea_OV · STG_Prod_OV · STG_Atributos_OV
//
// POR QUÉ EXISTE
//   Aporta lo que el extracto de picking no tiene: la acción comercial
//   y de abastecimiento sobre cada línea (atender con stock,
//   trasladar, comprar), la disponibilidad por almacén, el precio y
//   los atributos del producto. De esta fuente sale la columna Accion,
//   que resultó el factor dominante del problema y que no estaba en el
//   pedido original de gerencia.
//
// DECISIONES CLAVE
//   · Se quitan DOCE columnas que ya vienen en el extracto de picking
//     (Cliente, F.Emision, Vendedor, Guia, Fecha GR, Factura, Fecha
//     FT, Forma de Entrega, Almacen, Dia, Mes, Prioridad). Conservar
//     ambas copias habría obligado a decidir cuál es la verdadera en
//     cada medida. La regla aplicada: cada dato tiene UNA sola fuente
//     de verdad en el modelo.
//   · Fecha_Comprometida se tipa con configuración regional explícita
//     ("es-PE"), no con detección automática. Es el único blindaje
//     contra que una fecha dd/mm/aaaa se interprete como mm/dd/aaaa —
//     un error que no da mensaje y mueve miles de registros de mes.
//   · El correlativo del export (la columna #) se quita antes de
//     deduplicar, por la misma razón que en 01_picking_base: con esa
//     columna presente cada fila es única y Table.Distinct no
//     encuentra nada.
//   · Numero_OV se convierte a TEXTO y se renombra Nro_Doc, igual que
//     en la otra base. Sin esa coincidencia de nombre y tipo la
//     relación del modelo no se puede crear.
//   · El filtro por Almacen = PRI-FIS se aplica DESPUÉS de tipar, no
//     antes: tipar sobre el conjunto completo garantiza que un valor
//     atípico fuera del universo no pase inadvertido como error de
//     tipo.
// ────────────────────────────────────────────────────────────────────

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
