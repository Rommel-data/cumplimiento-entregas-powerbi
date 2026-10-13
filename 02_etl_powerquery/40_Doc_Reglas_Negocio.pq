// ────────────────────────────────────────────────────────────────────
// Doc_Reglas_Negocio
//
// Capa       : Documentación  ·  CARGADA al modelo
// Origen     : Tabla escrita a mano (Enter Data)
// Grano      : Una fila por regla de negocio
// Filas      : 8
// Entrega a  : Página Calidad del tablero
//
// POR QUÉ EXISTE
//   Es la trazabilidad dentro del propio modelo. Cada regla usada en
//   el análisis queda con su valor, su fuente y su tipo: Documentado
//   (está en el procedimiento de la empresa), Supuesto (lo definió el
//   analista) o Pendiente (nadie lo ha definido). Vivir como tabla y
//   no como texto en una diapositiva significa que el lector del
//   tablero la ve sin que nadie se la cuente.
//
// DECISIONES CLAVE
//   · La fila más valiosa es la que dice «Meta de cumplimiento: no
//     definida». Declarar lo que la empresa NO tiene es un hallazgo,
//     no una omisión: sin meta formal no se puede afirmar si 51,1 % es
//     aceptable o crítico.
//   · Los umbrales del semáforo (15 % y 30 %) están marcados como
//     supuesto. Un umbral inventado presentado como norma es la forma
//     más fácil de perder credibilidad.
// ────────────────────────────────────────────────────────────────────

let
    Origen = Table.FromRows(Json.Document(Binary.Decompress(Binary.FromText("rdLBSsRADAbgVwkFbyt0XfXgTdrjKuLiaekhnWbpLDNNyUz3HXyMgi/gM/RNfBIzu70KRb0Nk/wfCWS/z3bbR3glw0cG6iBa6hrMVtkNtCwYoJ3G2joK+vUibKixXlsiB+hREOScDFCU2lCyGbwWseGsWl3okkKPpmXYskGX4NtlcjMHl9iaP9nOWPw/v2CJBB6nT+wSu84fNvlfqIjSUILufw29+VrQQSA/jQcWhhNdzK/3D1jfXemrEBtJLCvlQCd3NsQ0/m7oBwrxB2cafY0yQ5t8MfREMQ0NOmbv5lW05zmlDraz50u6TsvqVaUqZVX1DQ==", BinaryEncoding.Base64), Compression.Deflate)), let _t = ((type nullable text) meta [Serialized.Text = true]) in type table [Regla = _t, Valor = _t, Fuente = _t, Tipo = _t])
in
    Origen
