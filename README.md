![Power BI — ETL, modelo dimensional y DAX](Picture/banner.png)

# Cumplimiento de plazos de entrega — Centro de Distribución

**Me pidieron medir cuántos pedidos entraban después de las 7 de la noche. Eran el 2,21 % del total — y los que mejor cumplían.** Este es el proyecto de Power BI que, en vez de entregar ese número, encontró las dos causas que sí explicaban que uno de cada dos pedidos llegara tarde.

`Power BI` · `Power Query (M)` · `DAX` · `Modelo dimensional en constelación`

Distribuidor mayorista de materiales eléctricos · Enero – Julio 2025 · 18.538 pedidos · 2 fuentes, 270.703 registros crudos

![Página de resumen del tablero](Picture/01-resumen.png)

## 📩 Conéctate conmigo

¿Tienes un proceso donde nadie sabe por qué se incumple, datos repartidos entre Excel y el ERP, o un tablero que muestra mucho y no termina en ninguna decisión? Eso es lo que resuelvo: entender el negocio, modelar el dato y dejar un indicador que alguien pueda accionar.

<p align="center">
  <a href="https://www.linkedin.com/in/rommel-aar%C3%B3n-reynaga-alvarado-470299222/">
    <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=flat-square&logo=linkedin&logoColor=white" />
  </a>
</p>

## 🗂️ Estructura del Proyecto

1. [🎯 El problema y las hipótesis](#-1-el-problema-y-las-hipótesis)
2. [🔧 Los datos: extracción y transformación](#-2-los-datos-extracción-y-transformación)
3. [🧩 El modelo dimensional](#-3-el-modelo-dimensional)
4. [📊 Las medidas y el tablero](#-4-las-medidas-y-el-tablero)
5. [⚠️ Alcance y limitaciones](#-5-alcance-y-limitaciones)

---

## 🎯 1. El problema y las hipótesis

La gerencia de operaciones pidió un dato puntual: el porcentaje de órdenes de venta que ingresan después de las 19:00. La hipótesis implícita era que los pedidos tardíos congestionaban el día siguiente.

El problema real era otro: **el 51,1 % de los pedidos no llegaba dentro del plazo prometido al cliente** — 9.324 pedidos, con S/ 48,27 millones de facturación expuesta a reclamo. El indicador se mantiene entre 49,5 % y 54,2 % durante los siete meses, sin estacionalidad: es crónico y estructural.

La hora de ingreso era un síntoma que alguien asumió como causa. Antes de responder lo que me pidieron, verifiqué si era cierto.

### Las cinco hipótesis, con su criterio de refutación definido antes de medir

| # | Hipótesis | Qué la daría por falsa | Veredicto |
|---|---|---|---|
| H1 | La hora de ingreso explica el incumplimiento | Que las franjas horarias muestren tasas similares entre sí | ❌ **Refutada** |
| H2 | La carga diaria del almacén lo explica | Que no haya relación creciente entre volumen y tiempo | ❌ **Refutada** |
| H3 | La complejidad del pedido lo explica | Que el tiempo se mantenga plano al aumentar las líneas | ✅ Confirmada |
| H4 | La disponibilidad del producto lo explica | Que el tiempo sea similar con y sin stock | ✅ Confirmada |
| H5 | Algún plazo prometido no es alcanzable | Que la mediana de cada modalidad esté dentro de su plazo | ✅ Confirmada |

El criterio de refutación es lo que convierte una sospecha en hipótesis: define por adelantado qué resultado la daría por falsa. Sin él, cualquier gráfico confirma lo que uno ya creía.

![Página de diagnóstico](Picture/02-diagnostico.png)

### Lo que la evidencia descartó

**La hora de ingreso no explica nada.** Las seis franjas se mueven entre 41,7 % y 53,0 %: once puntos de rango contra un incumplimiento general del 51,1 %. La franja nocturna —la sospechosa— es la que **menos** incumple.

**La carga del almacén tampoco.** El almacén procesa entre 110 y 170 pickings diarios y el tiempo se mantiene entre 5 y 10 horas hábiles, muy por debajo de las 24 comprometidas. Más carga no produce más demora: no se satura. Este hallazgo descartó ampliar la dotación, que era la decisión más costosa sobre la mesa.

### Las dos causas reales, y una falla de diseño

| Factor | Efecto |
|---|---|
| **Disponibilidad de stock** | Con el producto en almacén, el 49,33 % llega tarde. Si requiere traslado, 78,25 %. Si hay que comprarlo, **86,88 %**. El problema nace antes del almacén, en abastecimiento |
| **Complejidad del picking** | Hasta 15 líneas se prepara en 6-9 horas, dentro del plazo. A partir de 16 líneas el tiempo salta a **31 horas** y rompe las 24 comprometidas |
| **El plazo de recojo** | Promete **2 horas hábiles** sobre un proceso cuya mediana real es **4,2 horas**. Su 76,3 % de incumplimiento no mide una falla del equipo: mide una promesa que el proceso nunca pudo cumplir |

La tercera es la corrección más barata del proyecto —un parámetro, no un proceso— y la de mayor impacto, porque es la modalidad con la peor tasa.

---

## 🔧 2. Los datos: extracción y transformación

### Las fuentes

| | Fuente 1 | Fuente 2 |
|---|---|---|
| **Qué es** | Listado de documentos de picking | Listado de órdenes de venta |
| **Sistema** | ERP — módulo de almacén | ERP — módulo comercial |
| **Registros crudos** | 108.988 × 30 columnas | 161.715 × 32 columnas |
| **Grano** | Una fila por línea de picking | Una fila por línea de orden |
| **Qué aporta** | Fechas y horas de todo el ciclo, cantidades, modalidad de entrega | Acción de abastecimiento, stock por almacén, precio, atributos del producto |

**Universo analizado:** solo el almacén del CD, solo órdenes de venta, solo 2025. Resultado: 70.493 filas de picking · 21.761 pickings · 18.538 pedidos · **98,52 % con tiempo medible**.

Los archivos de origen no están en este repositorio: son datos de una empresa real. El código exportado en [`Scripts/`](Scripts/) permite auditar cada transformación sin exponerlos.

### La arquitectura del ETL

Dieciocho consultas en Power Query, por capas, numeradas en orden de dependencia. Nueve entran al modelo; las demás son andamiaje con la carga deshabilitada.

| Capa | ¿Entra al modelo? | Se construye con |
|---|---|---|
| Función personalizada | No | — |
| Base *(lectura del Excel + limpieza)* | **No** | Filtros, tipado, deduplicación |
| Staging | **No** | Agrupar por |
| Dimensión | Sí | Agrupar por |
| Hechos | Sí | **Elegir columnas** |
| Documentación | Sí | Enter Data |

Las consultas derivadas son **referencias** a la base, no duplicados. Un arreglo en la base se propaga a las nueve que dependen de ella; con duplicados habría que arreglar nueve veces lo mismo — y olvidarse de una.

![Árbol de dependencias de consultas](Picture/dependencias-consultas.png)

### Las cuatro trampas del dato

Lo que separa un ETL que corre de uno que dice la verdad. Las cuatro se detectaron con **números de control**, no leyendo columnas.

#### 1 · Un importe que no se puede sumar

`DOC_VENTA_SOL` venía repetido en cada línea del detalle: es un dato de cabecera alojado en el detalle. Sumarlo directo daba **S/ 116,75 M contra S/ 82,23 M reales — un 42 % de inflación.**

```m
// Dos agrupaciones encadenadas: la primera colapsa la repetición,
// la segunda suma los valores ya únicos.
#"Quitar repeticion por OV y SKU" =
    Table.Group(Origen, {"Nro_Doc", "Cod_Sap"},
        {{"Valor_Linea", each List.Max([Doc_Venta_Sol]), type nullable number}}),
#"Sumar valor por OV" =
    Table.Group(#"Quitar repeticion por OV y SKU", {"Nro_Doc"},
        {{"Valor_OV", each List.Sum([Valor_Linea]), type nullable number}})
```

#### 2 · Un vacío que no era un vacío

El 68,9 % de los pedidos de recojo no tiene guía de remisión. No era un dato faltante: **es cómo cierra ese proceso** — un recojo se cierra con la factura. Entenderlo subió la cobertura medible del 66,9 % al **98,52 %**.

```m
FechaHora_Fin =
    if [Modo_Entrega] = "Recojo en tienda" then [FechaHora_FA]
    else if [FechaHora_GR] <> null         then [FechaHora_GR]
    else [FechaHora_FA]
```

#### 3 · Horas calendario que mentían

La política de la empresa está en **horas hábiles**. Un pedido emitido un viernes a las 18:00 no lleva 60 horas de retraso el lunes: lleva las que el almacén estuvo abierto. La función está parametrizada con cuatro horarios, así que sirve a las dos modalidades con ventanas operativas distintas.

```m
(Inicio as nullable datetime, Fin as nullable datetime,
 AbreLV as number, CierraLV as number,
 AbreSab as number, CierraSab as number) as nullable number =>
    // Lista los días del intervalo, calcula la intersección entre la ventana
    // operativa de cada día y el intervalo real, y suma.
    // Devuelve null si falta una fecha: un null se clasifica como "sin medición";
    // un cero se contaría como cumplimiento perfecto.
```

#### 4 · Una tabla de hechos que perdió 5.683 filas en silencio

La primera versión de `F_Linea_Picking` usó **Agrupar por** en lugar de **Elegir columnas**: 64.810 filas en vez de 70.493, y 2.951.168 unidades menos. **No dio ningún error.** Se detectó comparando el conteo contra la base.

> **La regla que salió de ahí:** dimensión → Agrupar por. Hechos → Elegir columnas. En una tabla de hechos el conteo de filas **nunca** cambia al reducir columnas. Si bajó, se usó la herramienta equivocada.

---

## 🧩 3. El modelo dimensional

![Modelo relacional](Picture/modelo-relacional.png)

Es una **constelación de hechos**, no una estrella ni un copo de nieve: dos tablas de hechos (`F_Linea_OV` y `F_Linea_Picking`) comparten las mismas dimensiones conformadas.

**Por qué esa forma y no otra.** El indicador vive a nivel de pedido, pero los dos procesos que lo producen tienen granos distintos: la línea comercial y la línea de picking. Analizarlos juntos sin duplicar conteos exige dos tablas de hechos y dimensiones compartidas. Las dimensiones que al principio colgaban de otra dimensión se **aplanaron por merge** — el modelo quedó limpio sin perder un solo atributo.

| Decisión | Por qué |
|---|---|
| `Dim_OV` es **dimensión**, no tabla de hechos | El KPI vive a nivel de pedido. Así cada medida es un `COUNTROWS` en vez de un `DISTINCTCOUNT` sobre detalle, con riesgo permanente de duplicar |
| Un solo calendario con **relaciones inactivas** | Sirve a tres fechas distintas vía `USERELATIONSHIP`, en vez de tres calendarios que triplicarían los segmentadores |
| Las tablas de hechos llevan **solo llaves y métricas** | Todo lo que sirve para filtrar vive en una dimensión |
| Los plazos en una **tabla de parámetros** | Recalibrar un SLA es editar una celda, no catorce fórmulas — que es justo la recomendación del informe |

---

## 📊 4. Las medidas y el tablero

Cuarenta y cinco medidas alojadas en una tabla vacía, agrupadas en carpetas. Estas cuatro existen porque **sin ellas el número habría estado mal**; el resto son variantes de formato.

**Un juicio con tres valores, no dos.** Un pedido sin fecha de cierre no es un pedido cumplido:

```dax
Cumple_SLA =
SWITCH( TRUE(),
    ISBLANK( Dim_OV[LeadTime_Hab] ),            "Sin medicion",
    Dim_OV[LeadTime_Hab] <= Dim_OV[SLA_Horas],  "Cumple",
                                                "Incumple" )
```

**El denominador correcto** — los medibles, nunca el total:

```dax
% Incumplimiento SLA = DIVIDE( [OVs Fuera de SLA], [OVs Medibles] )
```

**`REMOVEFILTERS` en numerador y denominador.** La primera versión de esta medida daba 1,63 % porque `CALCULATE` sobrescribía el segmentador en una parte y no en la otra — un conflicto de contexto de filtro que **no lanza ningún error**:

```dax
% OVs Post 19h =
VAR _Nocturnas = CALCULATE( [OVs],
                    REMOVEFILTERS( Dim_OV[Franja_Ingreso] ),
                    Dim_OV[Franja_Ingreso] = "6. Nocturno (>19:00)" )
VAR _Total     = CALCULATE( [OVs], REMOVEFILTERS( Dim_OV[Franja_Ingreso] ) )
RETURN DIVIDE( _Nocturnas, _Total )
```

**`CROSSFILTER` para cruzar la constelación.** El filtro nace en una tabla de hechos y tiene que llegar a una dimensión. Sin esto las tres categorías de abastecimiento mostraban el mismo valor — el otro error que no avisa:

```dax
% Incumplimiento por Accion =
CALCULATE( [% Incumplimiento SLA],
    CROSSFILTER( Dim_OV[Nro_Doc], F_Linea_OV[Nro_Doc], BOTH ) )
```

### El lenguaje DAX: las funciones que sostienen el tablero

| Función | Qué resuelve en este modelo |
|---|---|
| `VAR` / `RETURN` | Separa el cálculo de la decisión. Cada `VAR` se evalúa **una sola vez, antes del `RETURN`**, en el contexto donde se declara — así una medida reusa un valor tres veces sin recalcularlo |
| `CALCULATE` | La única función que **modifica el contexto de filtro**. Todo lo demás lo hereda; `CALCULATE` lo reescribe |
| `SWITCH( TRUE(), … )` | Condiciones encadenadas legibles en vez de `IF` anidados. **Evalúa en orden y se detiene en la primera verdadera** — el orden de las ramas es parte de la lógica |
| `DATEADD` | Desplaza el contexto de tiempo. No «va a buscar» el mes anterior: recalcula la misma medida sobre un período corrido |
| `USERELATIONSHIP` | Activa una relación dormida solo dentro de un cálculo. Un calendario sirviendo tres fechas |
| `CROSSFILTER` | Abre la propagación del filtro entre las dos tablas de hechos de la constelación |
| `REMOVEFILTERS` | Ignora un segmentador cuando la medida debe responder sobre el total |

#### La comparativa contra el mes anterior, nivel por nivel

El tablero compara cada KPI contra el mes previo. No es una medida: son **cuatro capas encadenadas**, y cada una existe por una razón distinta.

**Nivel 1 — el número base.** El denominador son los pedidos medibles, nunca el total:

```dax
% Incumplimiento SLA = DIVIDE( [OVs Fuera de SLA], [OVs Medibles] )
```

**Nivel 2 — el mismo número, un mes atrás.** `DATEADD` desplaza el contexto completo y la medida se recalcula ahí:

```dax
% Incumplimiento Mes Anterior =
CALCULATE(
    [% Incumplimiento SLA],
    DATEADD( Dim_Calendario[Date], -1, MONTH )
)
```

**Nivel 3 — la resta, con la guarda que la hace honesta.** Como `DATEADD` desplaza *todo el rango*, con los siete meses seleccionados compararía «ene–jul» contra «dic–jun» y la variación saldría ≈ 0. La guarda obliga a que haya **exactamente un mes activo**; si no, devuelve vacío en vez de un cero que parecería «no cambió nada»:

```dax
Var Incumplimiento MoM =
VAR _Meses  = DISTINCTCOUNT( Dim_Calendario[Anio_Mes] )
VAR _Actual = [% Incumplimiento SLA]
VAR _Previo = [% Incumplimiento Mes Anterior]
RETURN
    IF(
        _Meses <> 1 || ISBLANK( _Previo ) || ISBLANK( _Actual ),
        BLANK(),
        _Actual - _Previo
    )
```

**Nivel 4 — la lectura.** La variación no se muestra cruda: se convierte en flecha, signo y unidad. El umbral de ±0,5 pp es una **banda muerta**: sin ella, una diferencia de centésimas aparecería como «cambio» y el usuario reaccionaría a ruido.

```dax
Etiqueta Var Incumplimiento =
VAR _Var = [Var Incumplimiento MoM]
VAR _Flecha =
    SWITCH( TRUE(),
        ISBLANK( _Var ),  "",
        _Var >  0.005,    "▲",
        _Var < -0.005,    "▼",
                          "=" )
RETURN
    IF( ISBLANK( _Var ),
        "sin mes previo",
        _Flecha & " " & FORMAT( ABS( _Var ) * 100, "0.00" ) & " pp vs. mes anterior" )
```

> **El detalle que decide si el patrón funciona:** el umbral tiene que estar en la escala de la medida. En un porcentaje la banda es ±0,005; en horas es ±0,2. Replicar el patrón entre medidas de escalas distintas sin ajustar el umbral deja la flecha congelada en `=` **sin que nada falle y sin ningún mensaje de error.**

#### El semáforo: separar el número del juicio

Cada tarjeta muestra valor y color, pero son dos cosas distintas. La medida numérica alimenta ejes y formato condicional; la de texto solo vive en la tarjeta:

```dax
KPI Incumplimiento =
VAR _Valor = [% Incumplimiento SLA]
VAR _Semaforo =
    SWITCH( TRUE(),
        _Valor <= 0.15, "🟢",
        _Valor <= 0.30, "🟡",
                        "🔴" )
RETURN
    FORMAT( _Valor, "0.0%" ) & "  " & _Semaforo
```

En las tarjetas de conteo el semáforo juzga el **ratio**, no el valor absoluto: *226 pedidos fuera de plazo* no dice nada sin saber sobre cuántos. Mostrar el conteo y juzgar la proporción es la única combinación que no engaña cuando se lee la tarjeta con un filtro puesto.

**Los umbrales de este semáforo los definí yo, no la empresa** — y por eso están declarados en la página de Calidad del tablero. Un umbral inventado que se presenta como norma es la forma más rápida de perder credibilidad.

### El tablero

Tres páginas, cada una respondiendo **una** pregunta, más dos páginas de información emergente con navegación y filtrado cruzado.

| Página | Pregunta | Qué tiene |
|---|---|---|
| **Resumen** | ¿Qué está pasando y cuánto cuesta? | 5 KPI con semáforo, evolución mensual, incumplimiento por modalidad |
| **Diagnóstico** | ¿Por qué pasa? | Un panel por hipótesis, cada gráfico con su veredicto escrito debajo y la línea de referencia del plazo |
| **Calidad** | ¿Cuánto de esto puedo creer? | Cobertura, cada regla con su fuente, los datos que faltan y **cómo NO usar este informe** |

![Página de calidad](Picture/03-calidad.png)

**La página de Calidad es la que casi nadie hace.** Declara qué regla viene del procedimiento oficial, cuál la supuso el analista y cuál no existe — incluyendo que **la empresa no tiene meta formal de cumplimiento**, así que decir que 51,1 % es «malo» es criterio mío, no norma.

---

## ⚠️ 5. Alcance y limitaciones

### Qué demuestra este proyecto

| Capacidad | Dónde se ve |
|---|---|
| **Reformular el pedido del stakeholder** | El pedido era la hora de ingreso; el problema era el quiebre de stock |
| **Hipótesis falsables** | Criterio de refutación definido antes de medir, y dos hipótesis refutadas |
| **ETL con lenguaje M** | 18 consultas por capas, funciones parametrizadas, arquitectura de referencias |
| **Detectar errores silenciosos** | Campo no aditivo, filas perdidas por la herramienta equivocada, contexto de filtro |
| **Modelado dimensional** | Constelación de hechos, dimensiones conformadas, outriggers aplanados, relaciones inactivas |
| **DAX no trivial** | `USERELATIONSHIP`, `CROSSFILTER`, `REMOVEFILTERS`, guardas de período |
| **Diseño orientado a decisión** | Cada gráfico con su veredicto; un bloque de qué **no** hacer |
| **Honestidad analítica** | Página de calidad, proxies declarados, hipótesis descartadas publicadas |

> El modelado dimensional y el ETL se trabajaron en conjunto con un colega senior en Power BI. La definición del problema, las hipótesis, las medidas, el diseño del tablero y el análisis son propios.

### Limitaciones

- **El segmento comercial del cliente no existe en la fuente.** Lo usado es una aproximación por comportamiento de compra, declarada como proxy. No sirve para decisiones comerciales por cliente.
- **No hay meta formal de cumplimiento.** Los umbrales del semáforo (15 % / 30 %) los definí yo. El juicio rojo/ámbar/verde es orientativo, no normativo.
- **291 pedidos de 2024 están excluidos.** Como ese backlog ya estaba fuera de plazo, el incumplimiento real es algo mayor al 51,1 % reportado.
- **No se puede separar la demora de almacén de la de facturación**: falta la hora de liberación del picking. Es el primer dato que pediría para cerrar el análisis.
- **El costo real del incumplimiento no se pudo cuantificar.** Los S/ 48,27 M son facturación *expuesta*, no una pérdida: calcularla exige datos de penalidades y recompra que la empresa no registra.

### Qué hay en este repositorio

| Ruta | Contenido |
|---|---|
| [`Scripts/etl-powerquery.pq`](Scripts/etl-powerquery.pq) | Las 18 consultas en lenguaje M, en orden de dependencia |
| [`Scripts/medidas-clave.dax`](Scripts/medidas-clave.dax) | Las medidas que resuelven un problema concreto, con su justificación |
| [`Picture/`](Picture/) | Modelo relacional, árbol de dependencias y las tres páginas del tablero |

El `.pbix` no está publicado: es un binario que contiene los datos de origen embebidos.
