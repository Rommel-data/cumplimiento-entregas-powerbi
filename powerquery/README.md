# `powerquery/`

El proceso ETL completo: cada consulta del modelo exportada desde el Editor
avanzado de Power Query, en archivos `.pq`.

Los archivos van numerados por **orden de dependencia**, no alfabéticamente, para
que se pueda seguir el recorrido del dato desde los dos Excel de origen hasta las
tablas que entran al modelo. La cabecera de cada archivo documenta su capa, su
grano, a quién alimenta y por qué está escrito así.

> Se llena en el paso 3.
