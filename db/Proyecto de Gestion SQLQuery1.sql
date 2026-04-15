create login Jorge
with password = '12345';

create user Jorge
for login Jorge;

create database Veterinaria;
use Veterinaria;
--creacción de tablas
create table Dueños (
Dueño_id INT primary key,
Nombre_Completo varchar(100),
Email varchar(100),
Telefono varchar(20),
Dirección varchar(150),
Tipo_Documento varchar(20),
Numero_Documento varbinary(max),
Fecha_Registro date 
);


create table Mascotas (
Mascota_id  INT primary key,
Nombre varchar(50),
Especie varchar(50),
Raza varchar(50),
Edad INT,
Peso Decimal(5,2),
Dueño_id INT Foreign key references Dueños(Dueño_id)

);



create table Veterinarios (
Veterinario_id INT Primary key, 
Nombre_Completo varchar(100),
Especialidad varchar(50),
Cedula_Profesional varbinary(max),
Usuario varchar(50),
Contraseña varbinary(max),
Estado varchar(20)

);

create table Consultas (
Consulta_id INT Primary key,
Mascota_id INT Foreign key references Mascotas(Mascota_id),
Veterinario_id INT Foreign key references Veterinarios(Veterinario_id),
Fecha_Consulta datetime, 
Motivo varchar(10),
Estado varchar(20)
);

create table Tratamientos(
Tratamiento_id INT Primary key, 
Consulta_id INT Foreign key references Consultas(Consulta_id),
Diagnostico varbinary(max),
Tratamiento varbinary(max),
Observaciones varbinary(max)
);

create table Facturas(
Factura_id INT Primary key,
Consulta_id INT Foreign key references Consultas(Consulta_id),
Fecha Date,
Total Decimal (10,2),
Metodo_Pago varchar(30),
Referencia_Pago varbinary(Max)
);

create table Detalle_Facturas(
Detalle_id INT Primary key,
Factura_id INT Foreign key references Facturas(Factura_id),
Concepto varchar(100),
Cantidad INT,
Precio_Unitario Decimal(10,2),
Subtotal Decimal(10,2)	
);

-- error de sistema
create table Errores(
error_id Int identity (1,1) primary key,
mensaje_error varchar(50),
numero_error Int,
severidad Int,
estado int,
fecha Datetime
);
--insertando datos en las tablas	
Insert into  Dueños(Dueño_id,Nombre_Completo,Email,Telefono,Dirección,Tipo_Documento,Numero_Documento,Fecha_Registro) 
values 
(1, 'Juan Perez Lopez', 'juan.perez@gmail.com', '5523900822', 'Av Reforma 123,CDMX', 'Pasaporte', encryptbykey(key_guid('ClaveSimetricaDatos'),'JPL123456'),'2024-03-01'),
(2, 'Maria Gonzalez Ruiz', 'maria.gonzalez@gmail.com', '5524500838', 'Municipio Libre,CDMX', 'INE',encryptbykey(key_guid('ClaveSimetricaDatos'),'MGR567897'), '2024-02-01'),
(3, 'Jose Vasquez', 'jose.vasquez@outlook.com', '5523025894', 'Portales,CDMX', 'Licencia', encryptbykey(key_guid('ClaveSimetricaDatos'), 'JV125902'), '2024-04-05'),
(4, 'Carlos Hernandez Soto', 'carlos.hernandez@gmail.com', '5614258945', 'Perisur,CDMX', 'INE',encryptbykey(key_guid('ClaveSimetricaDatos'),'CHS856915'), '2024-04-10'),
(5, 'Fernanda Ortega Ortiz', 'fernanda.ortega@outlook.com','5687451898', 'Coyoacan,CDMX', 'Licencia', encryptbykey(key_guid('ClaveSimetricaDatos'), 'FOO856978'), '2024-06-20')

Insert into Mascotas (Mascota_id,Nombre,Especie,Raza,Edad,Peso,Dueño_id) 
values
(1, 'Max', 'Perro', 'Labrador', 3, 25.50, 1),
(2, 'Luna', 'Gato', 'Siames', 2, 4.20, 2),
(3, 'Rocky', 'Perro', 'Bulldog', 5, 18.75, 3),
(4, 'Molly', 'Perro', 'Poodle', 1, 6.30, 4),
(5, 'Simba', 'Gato', 'Persa', 4, 5.10, 5)


Insert into Veterinarios(Veterinario_id,Nombre_Completo,Especialidad,Cedula_Profesional,Usuario,Contraseña,Estado)
values
(1, 'Dr. José Martínez López', 'Medicina General',encryptbykey(key_guid('ClaveSimetricaDatos'),'0x3132333435'), 'jmartinez',encryptbykey(key_guid('ClaveSimetricaDatos'),'0x7061737331'),'Activo'),
(2, 'Dra. Laura Hernández Ruiz', 'Cirugía', encryptbykey(key_guid('ClaveSimetricaDatos'),'0x3233343536'), 'lhernandez',encryptbykey(key_guid('ClaveSimetricaDatos'),'0x7061737332'), 'Activo'),
(3, 'Dr. Carlos Gómez Díaz', 'Dermatología', encryptbykey(key_guid('ClaveSimetricaDatos'),'0x3334353637'), 'cgomez',encryptbykey(key_guid('ClaveSimetricaDatos'),'0x7061737333'), 'Activo'),
(4, 'Dra. Ana Torres Silva', 'Odontología', encryptbykey(key_guid('ClaveSimetricaDatos'),'0x3435363738'), 'atorres',encryptbykey(key_guid('ClaveSimetricaDatos'),'0x7061737334'), 'Inactivo'),
(5, 'Dr. Miguel Sánchez Pérez', 'Radiología',encryptbykey(key_guid('ClaveSimetricaDatos'), '0x3536373839'), 'msanchez',encryptbykey(key_guid('ClaveSimetricaDatos'),'0x7061737335'), 'Inactivo')

Insert into Consultas(Consulta_id,Mascota_id,Veterinario_id,Fecha_Consulta,Motivo,Estado)
VALUES
(1, 1, 1, '2026-03-01 09:00:00', 'Chequeo', 'Completada'),

(2, 2, 2, '2026-03-02 10:30:00', 'Vacuna', 'Pendiente'),

(3, 3, 1, '2026-03-03 11:15:00', 'Fiebre', 'Completada'),

(4, 4, 3, '2026-03-04 12:45:00', 'Dolor', 'Cancelada'),

(5, 5, 2, '2026-03-05 14:20:00', 'Alergia', 'Completada')

select * from Consultas_Log_Insert

Insert into Tratamientos(Tratamiento_id,Consulta_id,Diagnostico,Tratamiento,Observaciones)
values
(1, 1,EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Infeccion estomacal'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Antibiotico por 5 dias'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Reposo en casa')),

(2, 2,EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Vacunacion anual'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Aplicacion de vacuna'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Proxima vacuna en 1 año')),

(3, 3,EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Fiebre alta'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Medicamento antipiretico'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Control de temperatura')),

(4, 4,EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Dolor muscular'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Antiinflamatorio'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Evitar actividad fisica')),

(5, 5,EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Alergia alimentaria'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Cambio de dieta'),
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'Evitar alimento anterior'))


Insert into Facturas(Factura_id,Consulta_id,Fecha,Total,Metodo_Pago,Referencia_Pago)
values
(1, 1, '2026-03-01', 450.00, 'Efectivo',
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'REF-001')),

(2, 2, '2026-03-02', 320.50, 'Tarjeta',
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'REF-002')),

(3, 3, '2026-03-03', 280.75, 'Transferencia',
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'REF-003')),

(4, 4, '2026-03-04', 500.00, 'Efectivo',
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'REF-004')),

(5, 5, '2026-03-05', 150.25, 'Tarjeta',
EncryptByKey(Key_GUID('ClaveSimetricaDatos'), 'REF-005'))



Insert into Detalle_Facturas(Detalle_id,Factura_id,Concepto,Cantidad,Precio_Unitario,Subtotal)
values
(1, 1, 'Consulta general', 1, 300.00, 300.00),

(2, 2, 'Vacuna antirrabica', 1, 320.50, 320.50),

(3, 3, 'Medicamento antibiotico', 2, 140.00, 280.00),

(4, 4, 'Curacion de herida', 1, 250.00, 250.00),

(5, 5, 'Chequeo preventivo', 1, 390.00, 390.00);
select * from Dueños		

--1. Triggers (10%)
--Auditoría automática en consultas, tratamientos y facturas.
--	Cambio automático de estado de consulta.
create table Consultas_Log_Insert(
Id_Log int Primary Key identity (1,1),
Consulta_id INT,
Mascota_id INT,
Veterinario_id INT,
Fecha_Consulta DATETime,
Motivo Varchar (10),
Estado Varchar (20),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Consultas_Log_Update(
Id_Log_Up int Primary Key identity (1,1),
Consulta_id INT,
Mascota_id INT,
Veterinario_id INT,
Fecha_Consulta DATETime,
Motivo Varchar (10),
Estado Varchar (20),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Consultas_Log_Delete(
Id_Log_Del int Primary Key identity (1,1),
Consulta_id INT,
Mascota_id INT,
Veterinario_id INT,
Fecha_Consulta DATETime,
Motivo Varchar (10),
Estado Varchar (20),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Tratamientos_Log_Insert(
Id_Log INT Primary Key identity (1,1),
Tratamiento_id INT,
Consulta_id INT,
Diagnostico varbinary(max),
Tratamiento varbinary(max),
Observaciones varbinary(max),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Tratamientos_Log_Update(
Id_Log_Up INT Primary key identity (1,1),
Tratamiento_id INT,
Consulta_id INT,
Diagnostico varbinary(max),
Tratamiento varbinary(max),
Observaciones varbinary(max),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Tratamientos_Log_Delete(
Id_Log_Del INT Primary key identity (1,1),
Tratamiento_id INT,
Consulta_id INT,
Diagnostico varbinary(max),
Tratamiento varbinary(max),
Observaciones varbinary(max),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Facturas_Log_Insert(
Id_Log INT Primary key identity (1,1),
Factura_id INT,
Consulta_id INT,
Fecha Date,
Total Decimal (10,2),
Metodo_Pago varchar(30),
Referencia_Pago varbinary(Max),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Facturas_Log_Update(
Id_Log_Up INT Primary key identity (1,1),
Factura_id INT,
Consulta_id INT,
Fecha Date,
Total Decimal (10,2),
Metodo_Pago varchar(30),
Referencia_Pago varbinary(Max),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

create table Facturas_Log_Delete(
Id_Log_Del INT Primary key identity (1,1),
Factura_id INT,
Consulta_id INT,
Fecha Date,
Total Decimal (10,2),
Metodo_Pago varchar(30),
Referencia_Pago varbinary(Max),
Fecha_Registro DATETIME DEFAULT GETDATE()
);

--1triggers consultas 
create trigger trgafterinsertConsultas on Consultas after insert as begin
insert into Consultas_Log_Insert(Consulta_id,Mascota_id,Veterinario_id,Fecha_Consulta,Motivo,Estado)
select Consulta_id,Mascota_id,Veterinario_id,Fecha_Consulta, Motivo,Estado from inserted
end

create trigger trgafterdeleteConsultas on Consultas after delete as begin
insert into Consultas_Log_Delete(Consulta_id,Mascota_id,Veterinario_id,Fecha_Consulta,Motivo,Estado)
select Consulta_id,Mascota_id,Veterinario_id,Fecha_Consulta, Motivo,Estado from deleted
end

create trigger trgafterupdateConsultas on Consultas after update as begin
insert into Consultas_Log_Update(Consulta_id,Mascota_id,Veterinario_id,Fecha_Consulta,Motivo,Estado)
select Consulta_id,Mascota_id,Veterinario_id,Fecha_Consulta, Motivo,Estado from inserted
end
--triggers tratamientos
create trigger trgafterinsertTratamientos on Tratamientos after insert as begin
insert into Tratamientos_Log_Insert(Tratamiento_id,Consulta_id,Diagnostico,Tratamiento,Observaciones)
select Tratamiento_id,Consulta_id,Diagnostico,Tratamiento,Observaciones from inserted
end

create trigger trgafterdeleteTratamientos on Tratamientos after delete as begin
insert into Tratamientos_Log_Delete(Tratamiento_id,Consulta_id,Diagnostico,Tratamiento,Observaciones)
select Tratamiento_id,Consulta_id,Diagnostico,Tratamiento,Observaciones from deleted
end

create trigger trgafterupdateTratamientos on Tratamientos after update as begin
insert into Tratamientos_Log_Update(Tratamiento_id,Consulta_id,Diagnostico,Tratamiento,Observaciones)
select Tratamiento_id,Consulta_id,Diagnostico,Tratamiento,Observaciones from inserted
end

--triggers facturas
create trigger trgafterinsertFacturas on Facturas after insert as begin
insert into Facturas_Log_Insert(Factura_id,Consulta_id,Fecha,Total,Metodo_Pago,Referencia_Pago)
select Factura_id,Consulta_id,Fecha,Total,Metodo_Pago,Referencia_Pago from inserted 
end

create trigger trgafterdeleteFacturas on Facturas after delete as begin
insert into Facturas_Log_Delete(Factura_id,Consulta_id,Fecha,Total,Metodo_Pago,Referencia_Pago)
select Factura_id,Consulta_id,Fecha,Total,Metodo_Pago,Referencia_Pago from deleted
end

create trigger trgafterupdateFacturas on Facturas after update as begin
insert into Facturas_Log_Update(Factura_id,Consulta_id,Fecha,Total,Metodo_Pago,Referencia_Pago)
select Factura_id,Consulta_id,Fecha,Total,Metodo_Pago,Referencia_Pago from inserted
end

--2. Transacciones (10%)
--	Proceso completo: Consulta + Tratamiento + Factura.
--Uso de COMMIT y ROLLBACK.
--Manejo de errores con TRY/CATCH.


--3--. Procedimientos Almacenados (10%)
--	Registrar consulta.
--	Generar tratamiento cifrado.
--	Reportes de consultas por veterinario.

----Registrar dueño con datos cifrados.
if OBJECT_ID('Registrar_Dueño','P') is not null 
drop procedure Registrar_Dueño

create procedure Registrar_Dueño
@Nombre_Completo varchar(100),
@Email varchar(100),
@Telefono varchar(20),
@Dirección varchar(150),
@Tipo_Documento varchar(20),
@Numero_Documento varchar(50)
open symmetric key ClaveSimetricaDatos
Decryption by certificate CertificadoDatosSeguros;
Insert into Dueños(Nombre_Completo,Email,Telefono,Dirección,Numero_Documento)
values
(@Nombre_Completo,@Email,@Telefono,@Dirección,EncryptBykey(key_guid('ClaveSimetricaDatos'),convert(varchar(100),@Numero_Documento)));
close symmetric key ClaveSimetricaDatos;
End;
--Indices 
--Índice en email de Dueños.
---Índices en fechas y estados.

create nonclustered index Estudiantes_email  Dueños on Dueños(Email);

create nonclustered index Fecha_consulta Consultas on Consultas(Fecha);
create nonclustered index Estado_consulta Consultas on Consultas(Estado);

--TRY/CATCH (10%)
--	Manejo de errores con rollback.
--Registro en tabla de errores.

begin transaction 






--9. Seguridad y Cifrado de Datos (10%)
--Se deberá implementar:
--•	MASTER KEY
create master key 
encryption password = 'Veterinaria2024'
--•	CERTIFICATE
create certificate CertificadoDatosSeguros
with subject = 'Certificado para datos sensibles';
--•	SYMMETRIC KEY (AES_256)
create symmetric key ClaveSimetricaDatos
with algorithm = AES_256
encryption by certificate CertificadoDatosSeguros; 
--•	EncryptByKey
--•	DecryptByKey



--. Procedimientos Almacenados (10%)
--Registrar dueño con datos cifrados.
--	Registrar consulta.
--	Generar tratamiento cifrado.
--	Reportes de consultas por veterinario.
if OBJECT_ID('Registrar_Dueños','P'


-- 
create sequence seq_factura start with  1 increment by 1;
create sequence seq_Mascotas start with 1 increment by 1;
