todo lo que se haga en la base de datos, cada insercion y actualizacion debe pasar por logs con scipts, incluyendo los cualquier begin y exception, ademas de que todo script debe estan en un begin exception

toda tabla con un checksum debe calcularce automaticamente, para el calculo se puede ignorar los datos que pueden ser actualizables, por ejemplo estados o algo parecido

crear un scrip para que cada vez que se haga algo en las tablas(exepto en tablas que no se actualicen, osea que sean estaticas), se inserte en log un nuevo registro con los datos correspondientes

Crear un scrip para que cada vez que una tabla con el campo usuarioModificacion haga algo, se actualice ese usuario en el campo ultimoLogin

Crear un script par que cree todas las tablas del proyecto en la tabla llamada Tablas

En la tabla Dirreciones:
1 verificar que divisionID sea el nivel mas bajo de nivelesGeograficos del pais
2 en direccionCompleta Generador automáticamente en el script, hagarrando los datos de division id y creando un texto pasando por todas las autoreferencias(las mismas tambien deben ser agregadas) hasta llegar al nivelID es 1, a demas de calle, número y referencia cada que se inserta los datos en esta tabla

cuando se actualice TiposCambio crear historial con triggerCambios ademas de actualizar la anterior fechaFin 

igual en historial de cambios que fechaFin sea automaticamente 9999 el año cuando un registro nuevo se cree

cada vez que se haga una orden, debe de crearse un registro en transacciones automaticamente, ademas de que se debe actulizar el inventario, de igual manera automaticamente, y tambien el estado de cuenta

Por ultimo, cada que en estadosCuenta, estado cambie a completado, se debe actualizar el balanceNeto

En OrdenDetalles Verificar mendiante un trigger, a la hora de crear un orden detalle, que se escoja automaticamente el loteID mas actiguo del producto que aun tenga disponible, a demas de que si en ese lote hay menos productos disponibles del que se requiere, se cree automaticamente una ordendetalle nueva, con los mismos datos pero ajustando la cantidad segun corresponda, ademas de restar automaticamente en el lote o sumar segun el tipo del ordenID.TipoOrden

Cuando se creen Orden Detalles, OrdenDetallesImpuestos, OrdenDetalleDescuentos, actualicen los datos correspondientes de cada uno, por ejemplo, cuando se cree un ordendetalleDescuentos, se actualice descuentoFinal en ordenDetalle y precioLoteFinal, a su ves que se actualice precioFinal en ordenes, y todos los que se relacionen de la misma manera, valida con migo cuales consideras que caen en esta categoria antes de proceder.

cada que se crea una orden, se crea automaticamente un estado de cuenta, cada que se actualiza un estado de cuenta en el apartado de estado, se actualiza el balance neto solamente si se cambia a comletado