# Datos de origen

> **Los archivos de origen no están en este repositorio y no lo estarán.**
> Provienen del ERP de una empresa real y contienen razón social de clientes,
> nombres de vendedores e importes de venta. Lo que sigue describe su estructura
> para que el proceso sea auditable sin exponer los datos.

## Las dos fuentes

| | Archivo 1 | Archivo 2 |
|---|---|---|
| **Nombre** | `Listado de Picking - Documentos - Ene a Jul 2025.xlsx` | `Listado de OV.xlsx` |
| **Tabla interna** | `Tbl_Picking` | `Tbl_OV` |
| **Sistema que lo emite** | ERP — módulo de almacén | ERP — módulo comercial |
| **Filas crudas** | 108.988 | 161.715 |
| **Columnas** | 30 | 32 |
| **Grano** | Una fila por línea de documento de picking | Una fila por línea de orden de venta |
| **Período** | Enero – Julio 2025 | Enero – Julio 2025 |

## Qué aporta cada una

**Picking** — el lado operativo. Fechas y horas de emisión de la orden, de creación
del picking, de guía de remisión y de factura; cantidades solicitadas, abiertas y
preparadas; forma de entrega; comentarios del operario.

**OV** — el lado comercial y de abastecimiento. Acción sobre cada línea
(atender con stock, trasladar, comprar), disponibilidad por almacén, precio,
fecha comprometida, sucursal y destino, y los atributos del producto
(catálogo, marca, unidad de medida, proveedor).

## El universo analizado

| Filtro | Qué deja | Por qué |
|---|---|---|
| `DOC_ALMACEN = "PRI-FIS"` | Solo el Centro de Distribución Lima | Es el almacén del análisis; los demás operan con otros plazos |
| `Tipo_Doc = "OR"` | Solo órdenes de venta | Excluye transferencias y devoluciones, que no tienen compromiso de plazo con el cliente |
| `Fecha_Doc_Origen >= 2025-01-01` | Solo el período | Deja fuera 291 pedidos emitidos en 2024 (backlog que ya estaba fuera de plazo) |
| `Table.Distinct` | Filas únicas | Elimina 1.006 duplicados exactos del extracto |

**Resultado:** 70.493 filas de picking · 21.761 pickings · 18.538 pedidos.

## Columna descartada

`PICKING_FECHA` traía un reloj de 12 horas sin indicador AM/PM — las horas solo iban
de 1 a 12, nunca 0 ni 13+. Se conservó únicamente la parte de fecha
(`Fecha_Creacion_Picking`) y la hora se dio por irrecuperable.

## Cómo reproducir sin los archivos

El código M de todas las consultas está en [`../powerquery/`](../powerquery/) y
documenta cada transformación. Para correrlo con datos propios hace falta un
extracto con la misma estructura de columnas descrita arriba.
