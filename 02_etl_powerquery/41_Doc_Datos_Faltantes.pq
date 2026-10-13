// ────────────────────────────────────────────────────────────────────
// Doc_Datos_Faltantes
//
// Capa       : Documentación  ·  CARGADA al modelo
// Origen     : Tabla escrita a mano (Enter Data)
// Grano      : Una fila por dato que falta
// Filas      : 5
// Entrega a  : Página Calidad del tablero
//
// POR QUÉ EXISTE
//   Convierte los vacíos del análisis en un entregable. Cada fila dice
//   qué dato falta, para qué serviría y quién lo tiene — lo que
//   transforma una limitación en una petición concreta a un área
//   concreta. Es la diferencia entre decir «no se pudo medir» y decir
//   «Sistemas tiene que capturar la hora de liberación del picking
//   para separar la demora de facturación de la de almacén».
//
// DECISIONES CLAVE
//   · Las cinco filas son: dotación del almacén, hora de liberación
//     del picking, meta formal de cumplimiento, peso y volumen por
//     producto, y segmento comercial del cliente.
//   · Estar en el modelo y no en un anexo del informe hace que el dato
//     faltante sea visible cada vez que alguien abre el tablero.
// ────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("TZDNTsIxEMRfZdLEGxcIJt4l0YNGEi4mwGEpC1TbbtMPE3gjD558BF7M/RdJOPQy/e3M7C6XZsH7wLEKrATO1pHHlj2sd6qyGZkZ71xkFAeVk6eTgIsymEwhmD7gIJmKgo9XA7MeLc2ci+CIL/FN/ZEkI2XZNltF2RcCh5S5ENrwIlrY5J6N8WiCKpE9bbvvK3GpWYYvyvX8Y5uX0jOeNXmQvdtwJuvOv7GXT85+urjX2QUnypRVDf/sjmxtV/jYTX0ge/6OA+5K5UAX95nUG88bak6lW2JlDnRE1qadWxmQajvylSLekTgXiVRWRofeUq+oe13cX7kSdpLDZWnbQvIuDEeXXiQiDEQUFEZqrMxHO+01WMvcj3Gn1BNnjnpxs17/AQ==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [#"Dato faltante" = _t, #"Para qué serviría" = _t, #"Quién lo tiene" = _t])
in
    Origen
