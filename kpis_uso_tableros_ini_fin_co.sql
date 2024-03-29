USE [base_tablero] --Sustituir por el nombre de la base de datos del tablero.
GO
/****** Object:  View [dbo].[v_ra_uso_de_tableros]    Script Date: 28/12/2022 03:26:08 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_ra_uso_de_tableros] as
              with cte as (
                select '1' as id_sucursal,a.id_hd, a.fecha,
                  a.noorden,
                  a.noplacas,
                  anio = year(a.fecha),
                  mes = month(a.fecha),
                  dia = day(a.fecha),
                  tecnico = b.NOMBRE_EMPLEADO,
                  chip = 1,
				  t_real= isnull(datediff(minute, fecha_Hora_ini_Oper, isnull(fecha_hora_paro, fecha_hora_fin_oper)),0)/60.0,
                  diferencia_inicio = datediff(minute, fecha + cast(cast(a.horarampa as time) as datetime), a.fecha_hora_ini_oper),
                  tiempo = case when isnumeric(servicio) = 1 then cast(servicio as real) end,
                  detenida = case when Fecha_Hora_Paro is null then 0 else 1 end,
                  diferencia_fin = datediff(minute, dateadd(minute, case when isnumeric(servicio) = 1 then cast(servicio as real) end, fecha + cast(cast(a.horarampa as time)as datetime)), a.Fecha_Hora_Fin_Oper)
                from tb_citas a
                left join tb_tecnicos b on a.idTecnico = b.ID_EMPLEADO where  idTecnico not in ('L0','L1','L2','C1') 
              ),
              cte_ruidos as (
                    select distinct 1 asid_sucursal,id_hd
                    from tb_citas
                    where serviciocapturado like '%ruido%'
                    ),
                    cte_aceite as(
                    select distinct 1 as id_sucursal,id_hd
                    from Tb_CITAS
                    where servicioCapturado like '%aceite%'
                    ),cte_mantenimiento as(
                    select distinct 1 as id_sucursal,id_hd
                    from Tb_CITAS
                    where (serviciocapturado like '%revisi[oó]n%' or  serviciocapturado like '%revisar%' or serviciocapturado like '%mantenimiento%'or serviciocapturado like '%[0-9]KM%' )  
                    and serviciocapturado not like '%ruido%'),
                    cte_diagnostico as(
                    select distinct 1 as id_sucursal,id_hd
                    from tb_citas 
                    where serviciocapturado like '%Diagnosti%' ),
              cte_clasificacion as (
              select 
               1 as id_sucursal,
                t_c.id_hd,
                case 
                  when t_r.id_hd is not null and t_a.id_hd is not null and t_m.id_hd is not null and t_d.id_hd is not null then
                          'Ruidos //  Cambio de Aceite //  Revisiones De Mantenimiento // Diagnosticos'
                  when t_r.id_hd is not null and t_a.id_hd is null and t_m.id_hd is not null and t_d.id_hd is not null then
                          'Ruidos //  Revisiones De Mantenimiento // Diagnosticos'
                      when t_r.id_hd is not null and t_a.id_hd is not null and t_m.id_hd is null and t_d.id_hd is not null then
                          'Ruidos //  Cambio de Aceite // Diagnosticos'
                      when t_r.id_hd is not null and t_a.id_hd is not null and t_m.id_hd is not null and t_d.id_hd is null then
                          'Ruidos //  Cambio de Aceite // Revisiones De Mantenimiento'
                      when t_r.id_hd is null and t_a.id_hd is not null and t_m.id_hd is not null and t_d.id_hd is not null then
                          'Cambio de Aceite //  Revisiones De Mantenimiento // Diagnosticos'
                  when t_r.id_hd is not null and t_a.id_hd is not null and t_m.id_hd is null and t_d.id_hd is null then
                          'Ruidos //  Cambio de Aceite'
                  when t_r.id_hd is not null and t_a.id_hd is null and t_m.id_hd is not null and t_d.id_hd is null then
                          'Ruidos //  Revisiones De Mantenimiento'
                  when t_r.id_hd is not null and t_a.id_hd is null and t_m.id_hd is null and t_d.id_hd is not null then
                          'Ruidos //  Diagnosticos'
                  when t_r.id_hd is null and t_a.id_hd is not null and t_m.id_hd is not null and t_d.id_hd is null then
                          'Cambio de Aceite // Revisiones De Mantenimiento'
                  when t_r.id_hd is null and t_a.id_hd is not null and t_m.id_hd is null and t_d.id_hd is not null then
                          'Cambio de Aceite // Diagnosticos'
                  when t_r.id_hd is null and t_a.id_hd is null and t_m.id_hd is not null and t_d.id_hd is not null then
                          'Revisiones De Mantenimiento // Diagnosticos'
                  when t_r.id_hd is not null and t_a.id_hd is null and t_m.id_hd is null and t_d.id_hd is null then
                          'Ruidos'
                  when t_r.id_hd is null and t_a.id_hd is not null and t_m.id_hd is null and t_d.id_hd is null then
                          'Cambio de Aceite'
                  when t_r.id_hd is null and t_a.id_hd is null and t_m.id_hd is not null and t_d.id_hd is null then
                          'Revisiones De Mantenimiento'
                  when t_r.id_hd is null and t_a.id_hd is null and t_m.id_hd is null and t_d.id_hd is not null then
                          'Diagnosticos'
                  else 
                    'Otros'
                end as clasificacion
              from 
              Tb_CITAS t_c left join  cte_ruidos t_r on t_c.id_hd=t_r.id_hd 
                left join cte_aceite t_a on t_c.id_hd=t_a.id_hd  
                left join cte_mantenimiento t_m  on t_c.id_hd=t_m.id_hd 
                left join cte_diagnostico t_d on t_c.id_hd=t_d.id_hd 
				where idTecnico not in ('L0','L1','L2','C1'))
              select a.*,isnull(b.clasificacion,'- - -') as clasificacion,
                tipo_inicio = case when diferencia_inicio < 0 then 'Anticipada'
                  when diferencia_inicio between 0 and 10 then  'A Tiempo'
                  when diferencia_inicio > 10 then 'Tardía'
                  else 'No iniciada' end,
                tipo_fin = case when detenida = 1 then 'Detenida'
                  when diferencia_fin > tiempo*0.1 then 'Tardía'
                  when diferencia_fin between 0 and tiempo*0.1 then 'A Tiempo'
                  when diferencia_fin < 0 then 'Anticipada'
                  when diferencia_inicio is null then 'No iniciada'
                  else 'No finalizada' end
              from cte a left join cte_clasificacion b on a.id_sucursal=b.id_sucursal and a.id_hd=b.id_hd
GO
/****** Object:  View [dbo].[v_ra_uso_de_tableros_dasboard_rotacion]    Script Date: 28/12/2022 03:26:08 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[v_ra_uso_de_tableros_dasboard_rotacion] 
AS
SELECT Anio,
Mes,
dia,
CASE WHEN Tecnico IS NULL THEN 'Técnico no válido' ELSE tecnico END AS Tecnico,
clasificacion,
SUM(chip) Vehiculos
FROM dbo.v_ra_uso_de_tableros
WHERE detenida = 0
AND ISNULL(t_real,0) <> 0
AND tecnico IS NOT NULL
AND tecnico <> 'No Show'
GROUP BY Anio,
Mes,
dia,
tecnico,
clasificacion
GO
/****** Object:  View [dbo].[vV_TIEMPO_OPERACION_REAL_INI_FIN]    Script Date: 28/12/2022 03:01:36 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW [dbo].[vV_TIEMPO_OPERACION_REAL_INI_FIN]
AS
SELECT
 FECHA
,mes
,year
,DIA
,ID_ASESOR
,NOORDEN
,noPlacas
,IDTECNICO
,TECNICO
,servicioCapturado
,CON_CITA
,fecha_Hora_ini_Oper
,Fecha_Hora_Fin_Oper
,TIEMPO_ASIGNADO
,TIEMPO_OPERACION
,Fecha_Hora_Paro
,Fecha_Hora_Reinicio
,Tiempo_disponible_bahia
,TMP_diff_ini
,Status_Inicio
,CASE WHEN Status_Inicio = 'Anticipada' THEN 1 ELSE 0 END AS si_anticipada
,CASE WHEN Status_Inicio = 'A Tiempo' THEN 1 ELSE 0 END AS si_a_tiempo
,CASE WHEN Status_Inicio = 'Tardia' THEN 1 ELSE 0 END AS si_tardia
,CASE WHEN Status_Inicio = 'No Iniciada' THEN 1 ELSE 0 END AS si_no_iniciada
,TMP_DIFF_FIN
,DIFF_FIN_por
,Tmp_original
,SERVICIO
,horaRampa
,Estatus_Fin
,CASE WHEN Estatus_Fin = 'Anticipada' THEN 1 ELSE 0 END AS sf_anticipada
,CASE WHEN Estatus_Fin = 'Detenida' THEN 1 ELSE 0 END AS sf_detenida
,CASE WHEN Estatus_Fin = 'En Tiempo' THEN 1 ELSE 0 END AS sf_en_tiempo
,CASE WHEN Estatus_Fin = 'Tardia' THEN 1 ELSE 0 END AS sf_tardia
,CASE WHEN Estatus_Fin = 'No Finalizada' THEN 1 ELSE 0 END AS sf_no_finalizada
,cantidad
FROM vV_TIEMPO_OPERACION_REAL
GO
/****** Object:  StoredProcedure [dbo].[cargar_kpis]    Script Date: 28/12/2022 03:01:36 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[cargar_kpis] --exec cargar_kpis
AS
declare @min_fecha date = isnull((select top 1 fecha from dbo.kpis_tiempo order by fecha desc), concat(year(getdate())-2,'-01-01'));

	declare @dd int = datediff(day, @min_fecha, getdate());

	declare @fecha date;
	if @min_fecha <> cast(getdate()+1 as date)
		while @dd >= -1 
		begin
			set @fecha = getdate() - @dd;
			begin try
				insert into dbo.kpis_tiempo (fecha, anio, mes, dia, dw)
				values (@fecha, year(@fecha), month(@fecha), day(@fecha), datepart(dw, @fecha));
			end try
			begin catch
			end catch
			set @dd = @dd - 1;
		end

		set datefirst 1;
		set language spanish;

		update tb_citas_header_nw
		set fechaHoraPromesa=fecha_hora_com
		where fechaHoraPromesa is null and Fecha_hora_com is not null;

		drop table fv_productividad_total;
		select * into fv_productividad_total from vfv_productividad_total;

		drop table v_citas_show_noshow;
		select * into v_citas_show_noshow from vv_citas_show_noshow;

		drop table v_hit_bateo;
		select * into v_hit_bateo from vv_hit_bateo;

		drop table V_TIEMPO_OPERACION_REAL;
		select * into V_TIEMPO_OPERACION_REAL from vV_TIEMPO_OPERACION_REAL;

		drop table V_TIEMPO_OPERACION_REAL_INI_FIN;
		select * into V_TIEMPO_OPERACION_REAL_INI_FIN from vV_TIEMPO_OPERACION_REAL_INI_FIN;

		drop table V_TIEMPO_OPERACION_REAL_TECNICO;
		select * into V_TIEMPO_OPERACION_REAL_TECNICO from vV_TIEMPO_OPERACION_REAL_TECNICO;

		drop table fv_lavado_kpi
		select * into fv_lavado_kpi from v_lavado_kpi

		drop table fv_calidad_kpi
		select * into fv_calidad_kpi from v_calidad_kpi

		drop table v_pull_sys;
		select * into v_pull_sys from vv_pull_sys;

		drop table v_pull_sys_detalle;
		select * into v_pull_sys_detalle from vv_pull_sys_detalle;

		drop table v_pull_sys_ws;
		select * into v_pull_sys_ws from vv_pull_sys_ws;

		drop table v_dif_entrega;
		select * into v_dif_entrega from vv_dif_entrega;

		drop table v_uso_tableros_asesor_anfitrion;
		select * into v_uso_tableros_asesor_anfitrion from vv_uso_tableros_asesor_anfitrion;

		drop table fv_kpi_promedio_tiempos_express
		select * into fv_kpi_promedio_tiempos_express from v_kpi_promedio_tiempos_express

		drop table fv_productividad_eficiencia_y_efectividad;
		select * into fv_productividad_eficiencia_y_efectividad from v_productividad_eficiencia_y_efectividad;

		drop table fv_control_citas;
		select * into fv_control_citas from v_control_citas;

		drop table fv_productividad_calidad;
		select * into fv_productividad_calidad from vfv_productividad_calidad where T_Esp_Calidad >= '0';

		drop table fv_ra_uso_de_tableros_dasboard_rotacion;
		select * into fv_ra_uso_de_tableros_dasboard_rotacion from v_ra_uso_de_tableros_dasboard_rotacion;

exec editar_kpis
GO
