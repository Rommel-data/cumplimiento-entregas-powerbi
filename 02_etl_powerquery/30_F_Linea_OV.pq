// ────────────────────────────────────────────────────────────────────
// F_Linea_OV
//
// Capa       : Hechos  ·  CARGADA al modelo
// Origen     : Referencia a 02_OV_base
// Grano      : Una fila por línea de orden de venta
// Entrega a  : Dim_OV · Dim_Producto
//
// POR QUÉ EXISTE
//   Es la tabla de hechos que contiene la columna más importante de
//   todo el proyecto: Accion. De ahí sale la clasificación entre
//   atender con stock, trasladar desde otra sede o comprar al
//   proveedor — la hipótesis que resultó dominante y que no estaba en
//   el pedido original de gerencia.
//
// DECISIONES CLAVE
//   · Se construye con ELEGIR COLUMNAS, nunca con Agrupar por. En una
//     tabla de hechos el conteo de filas NO cambia al reducir
//     columnas: si baja, se usó la herramienta equivocada.
//   · Contiene solo llaves y métricas. Nada descriptivo: todo lo que
//     sirve para filtrar vive en una dimensión.
//   · UNA TABLA DE HECHOS NUNCA SE DEDUPLICA. Dos líneas idénticas del
//     mismo pedido pueden ser dos eventos reales.
// ────────────────────────────────────────────────────────────────────

let
    Origen = #"02_OV_base",
    #"Dejar llave y métricas" = Table.SelectColumns(Origen,{"Nro_Doc", "Cod_Sap", "Accion", "Prod_Stock", "Cantidad", "Stock", "Stock_Alm_Facturacion", "Stock_CD", "Precio", "Total"})
in
    #"Dejar llave y métricas"
