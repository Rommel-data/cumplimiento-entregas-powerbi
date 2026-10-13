// ────────────────────────────────────────────────────────────────────
// fnHorasHabiles  ·  función personalizada
//
// Capa       : Funciones  ·  carga deshabilitada
// Origen     : Ninguno — es una función, no una consulta
// Grano      : No aplica
// Entrega a  : 01_picking_base (columna LeadTime_Habil_Horas)
//
// POR QUÉ EXISTE
//   La política de plazos de la empresa está expresada en horas
//   hábiles, no calendario. Un pedido emitido un viernes a las 18:00
//   no lleva 60 horas de retraso el lunes a las 6:00: lleva las horas
//   que el almacén estuvo abierto. Sin esta función el indicador sería
//   falso para todo pedido emitido al cierre del día o antes de un
//   domingo.
//
// DECISIONES CLAVE
//   · Está parametrizada con cuatro horarios (apertura y cierre de
//     lunes a viernes, apertura y cierre del sábado) en lugar de
//     tenerlos escritos dentro. Así la misma función sirve para las
//     dos modalidades: recojo en tienda cierra a las 18:30 (1110 min)
//     y despacho a las 20:00 (1200 min).
//   · Los horarios se pasan en MINUTOS desde medianoche, no como hora.
//     Evita convertir tipos dentro del bucle.
//   · Domingo devuelve 0 horas: Abre = null y la rama corta antes de
//     calcular.
//   · Devuelve null si falta alguna de las dos fechas o si el fin es
//     anterior al inicio. Un null se propaga y se clasifica como «sin
//     medición»; un cero se contaría como cumplimiento perfecto.
//   · El patrón es: listar los días del intervalo, calcular la
//     intersección entre la ventana operativa de cada día y el
//     intervalo real, y sumar. Es más lento que una resta pero es el
//     único resultado correcto.
// ────────────────────────────────────────────────────────────────────


(Inicio as nullable datetime, Fin as nullable datetime,
 AbreLV as number, CierraLV as number,
 AbreSab as number, CierraSab as number) as nullable number =>
let
    Resultado =
        if Inicio = null or Fin = null or Fin < Inicio then null
        else
        let
            FechaIni = DateTime.Date(Inicio),
            FechaFin = DateTime.Date(Fin),
            Dias = List.Dates(
                     FechaIni,
                     Duration.Days(FechaFin - FechaIni) + 1,
                     #duration(1,0,0,0)
                   ),
            HorasPorDia = List.Transform(Dias, each
                let
                    Dia = _,
                    Dow = Date.DayOfWeek(Dia, Day.Monday),
                    Abre   = if Dow <= 4 then AbreLV   else if Dow = 5 then AbreSab   else null,
                    Cierra = if Dow <= 4 then CierraLV else if Dow = 5 then CierraSab else null,
                    Horas =
                        if Abre = null then 0
                        else
                        let
                            AbreDT   = DateTime.From(Dia) + #duration(0,0,Abre,0),
                            CierraDT = DateTime.From(Dia) + #duration(0,0,Cierra,0),
                            Desde = List.Max({Inicio, AbreDT}),
                            Hasta = List.Min({Fin, CierraDT})
                        in
                            if Hasta > Desde
                            then Duration.TotalHours(Hasta - Desde)
                            else 0
                in
                    Horas
            )
        in
            List.Sum(HorasPorDia)
in
    Resultado
