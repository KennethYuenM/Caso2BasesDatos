Motor de base de datos PostgradeSQL: 18
Nombre Base de datos:  Etheria Global: Sourcing & Logistics
Contexto: Esta empresa se encarga de la cadena de suministro. Importan productos naturales y curativos exóticos de todo el mundo (bebidas, alimentos, cosmética dermatológica, capilar, aromaterapia, jabones y aceites esenciales).
Todos los productos son de gama alta y poseen propiedades medicinales/saludables.
Se importan en "bulk" (cajas sin marca ni etiquetado) en dólares (USD).
Todo llega a un centro logístico en la costa Caribe de Nicaragua.

# Tables:

## Paises
- paisID (PK)  
- nombre varchar(30)
- codigoISO varchar (3)
- habilitado boolean

## NivelesGeograficos
- nivelID (PK)
- nombre varchar(50)
- orden int (Jerarquía 1 = más alto después del país)
- habilitado boolean

## DivisionesGeograficas
- divisionID (PK)
- paisID (FK)
- nivelID (FK)
- padreID (FK) (División padre auto-relación jerárquica puede ser nulo, solo si el nivelID.orden es = 1)
- nombre varchar(100)

## Direcciones
- direccionID (PK)
- divisionID (PK)
- calle varchar (150)
- número varchar(50)
- ciudadID (FK)
- referencia text
- codigoPostal varchar(20)
- direccionCompleta text (Generado automáticamente en el script)
- fechaCreacion timestamp
