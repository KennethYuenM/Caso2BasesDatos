call sp_orquestar_carga_etheria_global();
/* Pasos para ejecutar EG
1. Ejecutar el scrip Etheria Gloval.sql
2. Ejecutar EG Scrips y Function.sql
3. Ejecutar seedOrchestrationPostgres.sql
4. Ejecutar call sp_orquestar_carga_etheria_global();
*/

/*==============================================================*/
/* CONSULTAS RÁPIDAS DE VERIFICACIÓN                            */
/*==============================================================*/

SELECT count(*) AS totalUsuarios FROM usuarios;
SELECT count(*) AS totalPaises FROM paises;
SELECT count(*) AS totalProveedores FROM proveedores;
SELECT * FROM productos;
SELECT count(*) AS totalOrdenes FROM ordenes;
SELECT count(*) AS totalLogs FROM logs;

SELECT
    relname AS tabla,
    n_live_tup AS registros_aproximados
FROM pg_stat_user_tables
ORDER BY relname;