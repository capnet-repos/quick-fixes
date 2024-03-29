USE [base_tablero] --Sustituir por el nombre de la base de datos del tablero.
GO
/****** Object:  View [dbo].[v_productividad_eficiencia_y_efectividad_1]    Script Date: 02/01/2023 6:22:01 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[v_productividad_eficiencia_y_efectividad_1] AS
with cte as (
	select
		a.ID_EMPLEADO,
		b.fecha,
		CASE
			WHEN DATENAME(dw, b.fecha) IN ('Saturday', 'Sábado') THEN 
				ROUND(
					(SELECT DATEDIFF(minute, CAST(Hora_ent_s AS TIME), CAST(hora_sal_s AS TIME)) - MIN_COMER_S FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO)
				/ 60.0, 2)
			ELSE 
				ROUND(
					(SELECT DATEDIFF(minute, CAST(Hora_ent_lv AS TIME), CAST(hora_sal_lv AS TIME)) - MIN_COMER_lv FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO) 
				/ 60.0, 2)
		END Disponible,
		CASE
			WHEN DATENAME(dw, b.fecha) IN ('Saturday', 'Sábado') THEN 
				(SELECT cast(HORA_COMER_S as time) FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO)
			ELSE 
				(SELECT cast(HORA_COMER as time) FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO)
		END ComidaInicio,
		CASE
			WHEN DATENAME(dw, b.fecha) IN ('Saturday', 'Sábado') THEN 
				(SELECT cast(dateadd(minute,min_comer_s,cast(HORA_COMER_S as datetime)) as time) FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO)
			ELSE 
				(SELECT cast(dateadd(minute,min_comer_lv,cast(HORA_COMER as datetime)) as time) FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO)
		END ComidaFin,
		CASE
			WHEN DATENAME(dw, b.fecha) IN ('Saturday', 'Sábado') THEN 
				(SELECT top 1 min_comer_s FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO)
			ELSE 
				(SELECT top 1 min_comer_lv FROM Tb_TECNICOS b WHERE b.ID_EMPLEADO = a.ID_EMPLEADO)
		END TComida
		from Tb_TECNICOS a cross join kpis_tiempo b
), cte_tiempos_ausencias as (
	--select a.id_empleado, a.fecha, tiempo = datediff(minute, E1, S1)/60.0 from tb_ausencias a
	select a.id_empleado, a.fecha, tiempo = sum(datediff(minute, E1, S1)/60.0) from tb_ausencias a
	group by id_empleado, fecha
), cte_ordenes_operaciones as (
	select
		a.fecha,
		id_tecnico = a.idtecnico,
		a.noOrden,
		a.servicioCapturado,
		t_asignado = isnull(sum(cast(case when isnumeric(Tmp_original) = 1 then Tmp_original end as decimal(18,6))),0)/60.0,
		t_real = isnull(sum(datediff(minute, fecha_Hora_ini_Oper, isnull(fecha_hora_paro, fecha_hora_fin_oper))),0)/60.0
	from tb_citas a
    where a.tipoCliente <> 'Lavado'
    group by a.fecha, a.idTecnico, a.noOrden, a.servicioCapturado
), cte_fechas as (
	select a.*, b.cveGrupo as id_sucursal
	from kpis_tiempo a cross join [dbo].[SccGrupos] b
) select a.fecha AS FECHA, a.anio AS YEAR, right('0'+convert(varchar(3),a.mes),2) AS MES, right('0'+convert(varchar(3),a.dia),2) AS DIA, a.dw, 
                      TECNICO = c.NOMBRE_EMPLEADO, 
					  d.noOrden AS NOORDEN,d.servicioCapturado,
                      TMP_TOTAL_ASIGNADO = isnull(t_asignado,0), 
                      TMP_TOTAL_REAL = isnull(t_real,0),
                      Tiempo_disponible_bahia = case when f.tiempo > e.Disponible then 0 else (e.Disponible - isnull(f.tiempo,0))/(SELECT CASE WHEN COUNT(fecha)=0 THEN 1 ELSE COUNT(fecha) END FROM cte_ordenes_operaciones WHERE fecha=a.fecha AND id_tecnico=c.ID_EMPLEADO) end,
                      t_improductivo = case when f.tiempo > e.Disponible then 0 else (e.Disponible - isnull(f.tiempo,0))/(SELECT CASE WHEN COUNT(fecha)=0 THEN 1 ELSE COUNT(fecha) END FROM cte_ordenes_operaciones WHERE fecha=a.fecha AND id_tecnico=c.ID_EMPLEADO) - isnull(t_real,0) end					  
                  from kpis_tiempo a
                  cross join dbo.SccGrupos b
                  cross join tb_tecnicos c 
                  left join cte_ordenes_operaciones d on a.fecha = d.fecha and c.ID_EMPLEADO = d.id_tecnico
                  left join cte e on a.fecha = e.fecha and c.id_empleado = e.id_empleado
                  left join cte_tiempos_ausencias f on a.fecha = f.fecha and c.id_empleado = f.id_empleado
				  where a.dw <> 7 and c.NOMBRE_EMPLEADO <> 'no show'
				  	 and c.NOMBRE_EMPLEADO <> 'espera de repuestos' and c.NOMBRE_EMPLEADO <>'Vehiculos por asignar'
					 and c.Activo<>'false'
				 and a.fecha<>'20210807'  and a.fecha<>'20210816' and   a.fecha<>'20211018' and a.fecha<>'20211101'
				  and a.fecha<>'20211115'   and a.fecha<>'20211208' and a.fecha<>'20211225' 
				  --and t_asignado<>0
				   and a.fecha not like '2021-12-08' and a.fecha not like '2021-12-25' and a.fecha not like '2022-01-01'
				   and a.fecha not like '2022-01-01' and a.fecha not like '2022-01-10' and a.fecha not like '2022-03-21'
				   and a.fecha not like '2022-01-01' and a.fecha not like '2022-04-14' and a.fecha not like '2022-04-15'
				   and a.fecha not like '2022-05-30' and a.fecha not like '2022-06-20' and a.fecha not like '2022-06-27'
				   and a.fecha not like '2022-07-04' and a.fecha not like '2022-07-20' and a.fecha not like '2022-08-15' 
				   and a.fecha not like '2022-10-17' and a.fecha not like '2022-11-07' and a.fecha not like '2022-11-14'
				   and a.fecha not like '2022-12-08'
				   
GO
/****** Object:  View [dbo].[v_productividad_eficiencia_y_efectividad]    Script Date: 02/01/2023 6:22:01 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER VIEW [dbo].[v_productividad_eficiencia_y_efectividad]
AS
SELECT [FECHA]
      ,[YEAR]
      ,[MES]
      ,[DIA]
      ,[dw]
      ,[TECNICO]
      ,[NOORDEN]
      ,[servicioCapturado]
      ,[TMP_TOTAL_ASIGNADO]
      ,[TMP_TOTAL_REAL]
      ,[Tiempo_disponible_bahia]
	  ,[t_improductivo]
  FROM [dbo].[v_productividad_eficiencia_y_efectividad_1]
  WHERE CAST(fecha AS DATE) NOT IN (SELECT ausf.fecha FROM tb_ausencias_feriados ausf)
GO
