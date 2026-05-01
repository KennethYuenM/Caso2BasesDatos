begin;

call sp_orquestar_carga_etheria_global();

commit;

/* Pasos para ejecutar EG
1. Crear tablas
2. Insertar catálogos base (acciones, etc.)
3. Ejecutar etheria_global_seed.sql   ← AQUÍ
4. Crear funciones
5. Ejecutar sp_cargar_tablas
6. Crear triggers
7. Ejecutar call sp_orquestar_carga_etheria_global();
*/