// ────────────────────────────────────────────────────────────────────
// STG_ModoEntrega
//
// Capa       : Staging  ·  carga deshabilitada
// Origen     : Tabla escrita a mano (Enter Data)
// Grano      : Una fila por modalidad de entrega
// Filas      : 4
// Entrega a  : Dim_OV (SLA_Horas, Tipo_Reloj)
//
// POR QUÉ EXISTE
//   Es la TABLA DE PARÁMETROS del proyecto. Guarda el plazo
//   comprometido de cada modalidad y su ventana operativa, tomados del
//   procedimiento oficial de la empresa. Existir como tabla y no como
//   constante dentro de las fórmulas es lo que permite recalibrar un
//   SLA editando una celda en vez de catorce fórmulas — que es
//   justamente la recomendación principal del informe.
//
// DECISIONES CLAVE
//   · Contiene: Recojo en tienda 2 h · Despacho Local 24 h · Despacho
//     Provincia 24 h, todas en horas hábiles y todas documentadas en
//     el procedimiento.
//   · El binario comprimido es cómo Power Query guarda una tabla de
//     Enter Data. Para editarla: clic en el engranaje del paso Origen.
// ────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("pcwxD4IwEIbhv3LpDLEgAzI7ODAQSVwahuOo8UzpmZb4+60aTYwjw/cO3/AYo46W5CpgPSxs/YQqU2XaAUd2MEtcAk4S0tPmJ9B1o3Ve1M1WwwZ6HEHvXk+RqobMqL2NN6SLQCuE7olVXw3djGT9j1Xq1I/11qs/qwtyZ0+M67yePZDDyGcmDCus4QE=", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Modo_Entrega = _t, SLA_Horas = _t, Tipo_Reloj = _t, Ventana_Operativa = _t]),
    #"Tipo cambiado" = Table.TransformColumnTypes(Origen,{{"Modo_Entrega", type text}, {"SLA_Horas", Int64.Type}, {"Tipo_Reloj", type text}, {"Ventana_Operativa", type text}})
in
    #"Tipo cambiado"
