# Índice del ETL — Power Query (lenguaje M)

Las 18 consultas del modelo, exportadas desde el Editor avanzado. Numeradas por
**orden de dependencia**, no alfabéticamente: se puede seguir el recorrido del dato
desde los dos Excel de origen hasta las nueve tablas que entran al modelo.

La cabecera de cada archivo documenta su capa, su grano, a quién alimenta y **por qué
está escrito así** — incluidos los errores que costó llegar a esa versión.

## Las capas

| Prefijo | Capa | ¿Entra al modelo? | Se construye con |
|---|---|---|---|
| `00_` | Función personalizada | No | — |
| `01_` `02_` | Base | **No** | Lectura del Excel + limpieza |
| `1x_` | Staging | **No** | Agrupar por |
| `2x_` | Dimensión | Sí | Agrupar por |
| `3x_` | Hechos | Sí | **Elegir columnas** |
| `4x_` | Documentación y organización | Sí | Enter Data |

**Dieciocho consultas, nueve tablas en el modelo.** Las bases y los staging tienen la
carga deshabilitada: son andamiaje auditable que no ocupa memoria ni confunde al
usuario del tablero.

## Los archivos

| Archivo | Qué hace |
|---|---|
| `00_fnHorasHabiles.pq` | Función parametrizada que cuenta horas hábiles entre dos fechas, respetando el horario real de cada modalidad |
| `01_picking_base.pq` | Lee el Excel de picking, lo limpia y deriva las columnas de tiempo. **70.493 filas** |
| `02_ov_base.pq` | Lee el Excel de órdenes de venta: acción de abastecimiento, stock, precio y atributos del producto |
| `10_STG_Valor_OV.pq` | Resuelve el importe no aditivo con dos agrupaciones encadenadas |
| `11_STG_Atributos_OV.pq` | Lleva los atributos comerciales al grano de pedido |
| `12_STG_Prod_Picking.pq` | Mitad operativa del catálogo de productos |
| `13_STG_Prod_OV.pq` | Mitad comercial del catálogo de productos |
| `14_STG_Cliente.pq` | Segmenta clientes por frecuencia de compra (proxy declarado) |
| `15_STG_Vendedor.pq` | Segmenta vendedores por volumen de órdenes |
| `16_STG_ModoEntrega.pq` | **Tabla de parámetros**: el plazo comprometido de cada modalidad |
| `20_Dim_OV.pq` | **La unidad de análisis.** 18.538 pedidos, con 5 merge que aplanan el modelo |
| `21_Dim_Picking.pq` | 21.761 pickings, con el tramo de complejidad |
| `22_Dim_Producto.pq` | Dimensión conformada: sirve a las dos tablas de hechos |
| `30_F_Linea_OV.pq` | Hechos comerciales. Contiene `Accion`, la columna que explicó el problema |
| `31_F_Linea_Picking.pq` | Hechos operativos. 70.493 filas, idéntico a la base |
| `40_Doc_Reglas_Negocio.pq` | Cada regla con su fuente: documentada, supuesta o pendiente |
| `41_Doc_Datos_Faltantes.pq` | Qué dato falta, para qué serviría y quién lo tiene |
| `42__Medidas.pq` | Tabla vacía que aloja las ~45 medidas del modelo |

## La regla que atraviesa todo

Las consultas derivadas son **referencias** a la base, no duplicados. Una referencia
lee de la base en cada actualización, así que un arreglo en `01_picking_base` se
propaga a las nueve consultas que dependen de ella. Con duplicados habría que
arreglar nueve veces lo mismo — y olvidarse de una.
