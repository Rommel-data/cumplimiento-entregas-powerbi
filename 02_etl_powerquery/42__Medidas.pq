// ────────────────────────────────────────────────────────────────────
// _Medidas  ·  tabla vacía contenedora
//
// Capa       : Organización  ·  CARGADA al modelo
// Origen     : Tabla escrita a mano, sin columnas
// Grano      : Cero filas, cero columnas — a propósito
// Filas      : 0
// Entrega a  : Es el contenedor de las ~45 medidas del modelo
//
// POR QUÉ EXISTE
//   Es una tabla deliberadamente vacía cuya única función es alojar
//   las medidas. Sin ella, cada medida quedaría colgando de la tabla
//   sobre la que se calculó, y el panel de campos mezclaría columnas
//   de datos con cálculos. Con ella, el usuario del tablero ve un solo
//   lugar donde están todos los indicadores — y el guion bajo al
//   inicio del nombre la empuja al tope del panel.
//
// DECISIONES CLAVE
//   · El paso final quita la única columna que Enter Data obliga a
//     crear. Una tabla sin columnas no se puede crear directo: hay que
//     crearla con una y borrarla después.
//   · Las medidas se agrupan además en CARPETAS DE VISUALIZACIÓN
//     dentro de esta tabla (KPI, SLA, tiempos, tooltips), que es la
//     forma de ordenar 45 medidas sin que el panel sea una lista plana
//     imposible de recorrer.
// ────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("i44FAA==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Columna1 = _t]),
    #"Tipo cambiado" = Table.TransformColumnTypes(Origen,{{"Columna1", type text}}),
    #"Columnas quitadas" = Table.RemoveColumns(#"Tipo cambiado",{"Columna1"})
in
    #"Columnas quitadas"
