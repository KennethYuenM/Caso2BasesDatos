todo lo que se haga en la base de datos, cada insercion y actualizacion debe pasar por logs con scipts, incluyendo los cualquier begin y exception, ademas de que todo script debe estan en un begin exception

toda tabla con un checksum debe calcularce automaticamente, para el calculo se puede ignorar los datos que pueden ser actualizables, por ejemplo estados o algo parecido

crear un scrip para que cada vez que se haga algo en las tablas(exepto en tablas que no se actualicen, osea que sean estaticas), se inserte en log un nuevo registro con los datos correspondientes

Crear un scrip para que cada vez que una tabla con el campo usuarioModificacion haga algo, se actualice ese usuario en el campo ultimoLogin

Crear un script par que cree todas las tablas del proyecto en la tabla llamada Tablas

En la tabla Dirreciones:
1 verificar que divisionID sea el nivel mas bajo de nivelesGeograficos del pais
2 en direccionCOmpleta Generador automáticamente en el script, hagarrando los datos de division id y creando un texto pasando por todas las autoreferencias hasta llegar al nivelID es 1, a demas de calle, número y referencia cada que se inserta los datos en esta tabla

validar con trigger que moneda 1 y 2 no sean iguales en la tabla tiposCambio

cuando se actualice TiposCambio crear historial con triggerCambios ademas de actualizar la anterior fechaFin 

igual en historial de cambios que fechaDin sea automaticamente 9999 el año cuando un registro nuevo se cree

cada vez que se haga una orden, debe de crearse un registro en transacciones automaticamente, ademas de que se debe actulizar el inventario, de igual manera automaticamente, y tambien el estado de cuenta

Por ultimo, cada que en estadosCuenta, estado cambie a completado, se debe actualizar el balanceNeto