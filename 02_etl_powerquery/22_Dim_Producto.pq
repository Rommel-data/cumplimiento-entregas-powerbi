// ────────────────────────────────────────────────────────────────────
// Dim_Producto
//
// Capa       : Dimensión  ·  CARGADA al modelo
// Origen     : Anexado de STG_Prod_Picking + STG_Prod_OV
// Grano      : Una fila por código SAP
// Entrega a  : F_Linea_OV · F_Linea_Picking
//
// POR QUÉ EXISTE
//   Dimensión conformada: el mismo catálogo de productos sirve a las
//   DOS tablas de hechos. Es una de las piezas que convierten el
//   modelo en una constelación y no en dos estrellas independientes.
//
// DECISIONES CLAVE
//   · Se construye con ANEXAR (Table.Combine) y no con Combinar
//     consultas. Un merge habría dejado fuera los SKU que solo
//     aparecen en una de las dos fuentes; el anexado los conserva
//     todos y la agrupación posterior los consolida.
//   · Producto resuelve el nombre en cascada: primero la descripción
//     del picking, si falta el nombre comercial de la OV, y si faltan
//     ambos el texto literal «Sin descripcion». Nunca queda en null, y
//     el último caso es visible en vez de silencioso.
//   · Familia_Producto clasifica por el prefijo del texto del producto
//     con una cascada de ocho reglas. Es un PROXY del catálogo real,
//     que la empresa no entregó — está declarado como tal en las
//     limitaciones. El tramo «8. Otros» existe a propósito: sin él,
//     los productos no clasificados desaparecerían del análisis en vez
//     de quedar visibles.
// ────────────────────────────────────────────────────────────────────

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
