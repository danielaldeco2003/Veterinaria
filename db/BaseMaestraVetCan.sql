-- ==========================================
-- SCRIPT MAESTRO: CLÍNICA VETERINARIA
-- ==========================================

CREATE DATABASE ClinicaVeterinaria;
GO
USE ClinicaVeterinaria;
GO

-- ==========================================
-- 9. SEGURIDAD Y CIFRADO DE DATOS (10%)
-- ==========================================
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'VeterinariaPassword2026#';
GO

CREATE CERTIFICATE CertificadoVet
WITH SUBJECT = 'Certificado de Datos Sensibles';
GO

CREATE SYMMETRIC KEY ClaveVet
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertificadoVet;
GO

-- ==========================================
-- CREACIÓN DE TABLAS BASE
-- ==========================================
CREATE TABLE Duenos (
    dueno_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(150),
    tipo_documento VARCHAR(20),
    numero_documento VARBINARY(MAX), -- Cifrado
    fecha_registro DATE DEFAULT GETDATE()
);

CREATE TABLE Mascotas (
    mascota_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    especie VARCHAR(50),
    raza VARCHAR(50),
    edad INT,
    peso DECIMAL(5,2),
    dueno_id INT NOT NULL FOREIGN KEY REFERENCES Duenos(dueno_id)
);

CREATE TABLE Veterinarios (
    veterinario_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo VARCHAR(100) NOT NULL,
    especialidad VARCHAR(50),
    cedula_profesional VARBINARY(MAX), -- Cifrado
    usuario VARCHAR(50) NOT NULL UNIQUE,
    contrasena VARBINARY(MAX), -- Cifrado
    estado VARCHAR(20) DEFAULT 'Activo'
);

CREATE TABLE Consultas (
    consulta_id INT IDENTITY(1,1) PRIMARY KEY,
    mascota_id INT NOT NULL FOREIGN KEY REFERENCES Mascotas(mascota_id),
    veterinario_id INT NOT NULL FOREIGN KEY REFERENCES Veterinarios(veterinario_id),
    fecha_consulta DATETIME DEFAULT GETDATE(),
    motivo VARCHAR(150),
    estado VARCHAR(20) DEFAULT 'Pendiente'
);

CREATE TABLE Tratamientos (
    tratamiento_id INT IDENTITY(1,1) PRIMARY KEY,
    consulta_id INT NOT NULL FOREIGN KEY REFERENCES Consultas(consulta_id),
    diagnostico VARBINARY(MAX), -- Cifrado
    tratamiento VARBINARY(MAX), -- Cifrado
    observaciones VARBINARY(MAX) -- Cifrado
);

CREATE TABLE Facturas (
    factura_id INT IDENTITY(1,1) PRIMARY KEY,
    consulta_id INT NOT NULL FOREIGN KEY REFERENCES Consultas(consulta_id),
    fecha DATE DEFAULT GETDATE(),
    total DECIMAL(10,2),
    metodo_pago VARCHAR(30),
    referencia_pago VARBINARY(MAX) -- Cifrado
);

CREATE TABLE Detalle_Facturas (
    detalle_id INT IDENTITY(1,1) PRIMARY KEY,
    factura_id INT NOT NULL FOREIGN KEY REFERENCES Facturas(factura_id),
    concepto VARCHAR(100),
    cantidad INT,
    precio_unitario DECIMAL(10,2),
    subtotal DECIMAL(10,2)
);

-- ==========================================
-- 7. ÍNDICES (10%)
-- ==========================================
CREATE UNIQUE INDEX idx_duenos_email ON Duenos(email);
CREATE INDEX idx_consultas_fecha ON Consultas(fecha_consulta);
CREATE INDEX idx_consultas_estado ON Consultas(estado);

-- ==========================================
-- 5. SECUENCIAS (10%)
-- ==========================================
CREATE SEQUENCE seq_folio_factura
    START WITH 1000
    INCREMENT BY 1;
GO

-- ==========================================
-- 8. MANEJO DE ERRORES: TABLA LOG
-- ==========================================
CREATE TABLE Registro_Errores (
    error_id INT IDENTITY(1,1) PRIMARY KEY,
    numero_error INT,
    mensaje_error VARCHAR(500),
    procedimiento VARCHAR(100),
    fecha_error DATETIME DEFAULT GETDATE()
);

-- ==========================================
-- 4. TABLAS DE AUDITORÍA (10%)
-- ==========================================
CREATE TABLE Auditoria_Consultas (
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    consulta_id INT,
    accion VARCHAR(20),
    estado_anterior VARCHAR(20),
    estado_nuevo VARCHAR(20),
    fecha_accion DATETIME DEFAULT GETDATE(),
    usuario_bd VARCHAR(50) DEFAULT SYSTEM_USER
);

-- ==========================================
-- 1. TRIGGERS (10%)
-- ==========================================
GO
-- Trigger para auditar cambios en consultas
CREATE TRIGGER trg_Audit_Consultas
ON Consultas
AFTER UPDATE
AS
BEGIN
    INSERT INTO Auditoria_Consultas (consulta_id, accion, estado_anterior, estado_nuevo)
    SELECT i.consulta_id, 'UPDATE', d.estado, i.estado
    FROM inserted i
    INNER JOIN deleted d ON i.consulta_id = d.consulta_id;
END;
GO

-- Trigger para cambiar estado de consulta a 'Atendida' cuando se inserta un tratamiento
CREATE TRIGGER trg_Estado_Consulta_Atendida
ON Tratamientos
AFTER INSERT
AS
BEGIN
    UPDATE Consultas
    SET estado = 'Atendida'
    WHERE consulta_id IN (SELECT consulta_id FROM inserted);
END;
GO

-- ==========================================
-- 3 & 8. PROCEDIMIENTOS ALMACENADOS & TRY/CATCH (10%)
-- ==========================================

-- Procedimiento: Registrar Dueño (Cifrado)
CREATE PROCEDURE sp_Registrar_Dueno
    @nombre VARCHAR(100), @email VARCHAR(100), @tel VARCHAR(20), 
    @dir VARCHAR(150), @tipo_doc VARCHAR(20), @num_doc VARCHAR(50)
AS
BEGIN
    BEGIN TRY
        OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;
        
        INSERT INTO Duenos (nombre_completo, email, telefono, direccion, tipo_documento, numero_documento)
        VALUES (@nombre, @email, @tel, @dir, @tipo_doc, ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @num_doc));
        
        CLOSE SYMMETRIC KEY ClaveVet;
    END TRY
    BEGIN CATCH
        INSERT INTO Registro_Errores (numero_error, mensaje_error, procedimiento)
        VALUES (ERROR_NUMBER(), ERROR_MESSAGE(), 'sp_Registrar_Dueno');
    END CATCH
END;
GO

-- ==========================================
-- 2. TRANSACCIONES COMPLETAS (10%)
-- ==========================================
-- Proceso: Registrar Consulta + Tratamiento + Factura de un golpe
CREATE PROCEDURE sp_Proceso_Completo_Consulta
    @mascota_id INT, @veterinario_id INT, @motivo VARCHAR(150),
    @diagnostico VARCHAR(500), @tratamiento VARCHAR(500),
    @total DECIMAL(10,2), @metodo_pago VARCHAR(30)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Crear Consulta
        DECLARE @nueva_consulta_id INT;
        INSERT INTO Consultas (mascota_id, veterinario_id, motivo, estado)
        VALUES (@mascota_id, @veterinario_id, @motivo, 'Pendiente');
        SET @nueva_consulta_id = SCOPE_IDENTITY();

        -- 2. Crear Tratamiento (Cifrado)
        OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;
        INSERT INTO Tratamientos (consulta_id, diagnostico, tratamiento)
        VALUES (@nueva_consulta_id, 
                ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @diagnostico), 
                ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @tratamiento));
        CLOSE SYMMETRIC KEY ClaveVet;
        -- (Nota: El trigger trg_Estado_Consulta_Atendida cambiará la consulta a 'Atendida' automáticamente)

        -- 3. Crear Factura usando Sequence
        DECLARE @factura_id INT;
        INSERT INTO Facturas (consulta_id, total, metodo_pago)
        VALUES (@nueva_consulta_id, @total, @metodo_pago);
        SET @factura_id = SCOPE_IDENTITY();

        -- 4. Detalle de Factura
        INSERT INTO Detalle_Facturas (factura_id, concepto, cantidad, precio_unitario, subtotal)
        VALUES (@factura_id, 'Servicio Integral Veterinario', 1, @total, @total);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        INSERT INTO Registro_Errores (numero_error, mensaje_error, procedimiento)
        VALUES (ERROR_NUMBER(), ERROR_MESSAGE(), 'sp_Proceso_Completo_Consulta');
    END CATCH
END;
GO

-- ==========================================
-- 6. TÉCNICAS AVANZADAS (10%)
-- ==========================================

-- PIVOT: Consultas por mes
CREATE VIEW vw_Consultas_Por_Mes AS
SELECT * FROM (
    SELECT veterinario_id, DATENAME(MONTH, fecha_consulta) AS Mes, consulta_id 
    FROM Consultas
) AS DatosOrigen
PIVOT (
    COUNT(consulta_id)
    FOR Mes IN ([January], [February], [March], [April], [May], [June], [July], [August], [September], [October], [November], [December])
) AS TablaPivot;
GO

-- CASE: Clasificación de Clientes (Dueños)
CREATE VIEW vw_Clasificacion_Clientes AS
SELECT 
    d.nombre_completo,
    COUNT(c.consulta_id) as total_consultas,
    CASE 
        WHEN COUNT(c.consulta_id) >= 5 THEN 'Cliente VIP'
        WHEN COUNT(c.consulta_id) BETWEEN 2 AND 4 THEN 'Cliente Frecuente'
        ELSE 'Cliente Nuevo'
    END AS Categoria
FROM Duenos d
LEFT JOIN Mascotas m ON d.dueno_id = m.dueno_id
LEFT JOIN Consultas c ON m.mascota_id = c.mascota_id
GROUP BY d.dueno_id, d.nombre_completo;
GO

-- RANKING: Veterinarios con más consultas
CREATE VIEW vw_Ranking_Veterinarios AS
SELECT 
    v.nombre_completo,
    v.especialidad,
    COUNT(c.consulta_id) as total_atenciones,
    RANK() OVER (ORDER BY COUNT(c.consulta_id) DESC) as Posicion
FROM Veterinarios v
LEFT JOIN Consultas c ON v.veterinario_id = c.veterinario_id
GROUP BY v.veterinario_id, v.nombre_completo, v.especialidad;
GO

-- ==========================================
-- INSERCIÓN DE DATOS DE PRUEBA
-- ==========================================
-- Ejecutamos el SP para que la data ya entre cifrada
EXEC sp_Registrar_Dueno 'Juan Perez Lopez', 'juan.perez@gmail.com', '5523900822', 'Av Reforma 123', 'Pasaporte', 'JPL123456';
EXEC sp_Registrar_Dueno 'Maria Gonzalez', 'maria.gonzalez@gmail.com', '5524500838', 'Municipio Libre', 'INE', 'MGR567897';

-- Insertar Mascotas (Insert directo porque no lleva cifrado)
INSERT INTO Mascotas (nombre, especie, raza, edad, peso, dueno_id) VALUES 
('Max', 'Perro', 'Labrador', 3, 25.50, 1),
('Luna', 'Gato', 'Siames', 2, 4.20, 2);

-- Insertar Veterinarios con Cifrado Básico
OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;
INSERT INTO Veterinarios (nombre_completo, especialidad, cedula_profesional, usuario, contrasena) VALUES
('Dr. Jose Martinez', 'General', ENCRYPTBYKEY(KEY_GUID('ClaveVet'), 'CED123'), 'jmartinez', ENCRYPTBYKEY(KEY_GUID('ClaveVet'), 'pass123')),
('Dra. Laura Hernandez', 'Cirugia', ENCRYPTBYKEY(KEY_GUID('ClaveVet'), 'CED456'), 'lhernandez', ENCRYPTBYKEY(KEY_GUID('ClaveVet'), 'pass456'));
CLOSE SYMMETRIC KEY ClaveVet;

-- Probar la transacción completa (Esto llenará Consultas, Tratamientos, Facturas y Detalles de un solo golpe)
EXEC sp_Proceso_Completo_Consulta 
    @mascota_id = 1, @veterinario_id = 1, @motivo = 'Chequeo General',
    @diagnostico = 'Infeccion leve', @tratamiento = 'Antibiotico 5 dias',
    @total = 500.00, @metodo_pago = 'Efectivo';
GO


-- 1. Arreglar Ranking
ALTER VIEW vw_Ranking_Veterinarios AS
SELECT 
    v.nombre_completo AS veterinario,
    v.especialidad,
    COUNT(c.consulta_id) AS total_consultas,
    RANK() OVER (ORDER BY COUNT(c.consulta_id) DESC) AS ranking
FROM Veterinarios v
LEFT JOIN Consultas c ON v.veterinario_id = c.veterinario_id
GROUP BY v.veterinario_id, v.nombre_completo, v.especialidad;
GO

-- 2. Arreglar Clientes
ALTER VIEW vw_Clasificacion_Clientes AS
SELECT 
    d.nombre_completo AS dueno,
    COUNT(c.consulta_id) AS total_consultas,
    CASE 
        WHEN COUNT(c.consulta_id) >= 5 THEN 'Cliente VIP'
        WHEN COUNT(c.consulta_id) BETWEEN 2 AND 4 THEN 'Cliente Frecuente'
        ELSE 'Cliente Nuevo'
    END AS categoria
FROM Duenos d
LEFT JOIN Mascotas m ON d.dueno_id = m.dueno_id
LEFT JOIN Consultas c ON m.mascota_id = c.mascota_id
GROUP BY d.dueno_id, d.nombre_completo;
GO

-- 3. Arreglar PIVOT para que traiga el nombre del Doctor
ALTER VIEW vw_Consultas_Por_Mes AS
SELECT
    v.nombre_completo AS veterinario,
    ISNULL([January], 0) AS January, ISNULL([February], 0) AS February, ISNULL([March], 0) AS March,
    ISNULL([April], 0) AS April, ISNULL([May], 0) AS May, ISNULL([June], 0) AS June,
    ISNULL([July], 0) AS July, ISNULL([August], 0) AS August, ISNULL([September], 0) AS September,
    ISNULL([October], 0) AS October, ISNULL([November], 0) AS November, ISNULL([December], 0) AS December
FROM (
    SELECT c.veterinario_id, DATENAME(MONTH, c.fecha_consulta) AS Mes, c.consulta_id
    FROM Consultas c
) src
PIVOT (
    COUNT(consulta_id)
    FOR Mes IN ([January], [February], [March], [April], [May], [June], [July], [August], [September], [October], [November], [December])
) p
INNER JOIN Veterinarios v ON v.veterinario_id = p.veterinario_id;
GO

-- 1. Agregar el folio a las facturas
ALTER TABLE Facturas ADD folio INT;
GO

-- 2. Crear la tabla de auditoría para Facturas (Auditoría múltiple)
CREATE TABLE Auditoria_Facturas (
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    factura_id INT,
    accion VARCHAR(20),
    total_registrado DECIMAL(10,2),
    fecha_accion DATETIME DEFAULT GETDATE(),
    usuario_bd VARCHAR(50) DEFAULT SYSTEM_USER
);
GO

-- 3. Trigger para auditar facturas
CREATE TRIGGER trg_Audit_Facturas
ON Facturas
AFTER INSERT
AS
BEGIN
    INSERT INTO Auditoria_Facturas (factura_id, accion, total_registrado)
    SELECT i.factura_id, 'INSERT', i.total FROM inserted i;
END;
GO

ALTER PROCEDURE sp_Proceso_Completo_Consulta
    @mascota_id INT, @veterinario_id INT, @motivo VARCHAR(150),
    @diagnostico VARCHAR(500), @tratamiento VARCHAR(500),
    @total DECIMAL(10,2), @metodo_pago VARCHAR(30), @referencia VARCHAR(100) -- Agregamos referencia
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @nueva_consulta_id INT;
        INSERT INTO Consultas (mascota_id, veterinario_id, motivo, estado)
        VALUES (@mascota_id, @veterinario_id, @motivo, 'Pendiente');
        SET @nueva_consulta_id = SCOPE_IDENTITY();

        OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;
        INSERT INTO Tratamientos (consulta_id, diagnostico, tratamiento)
        VALUES (@nueva_consulta_id, 
                ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @diagnostico), 
                ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @tratamiento));
        
        -- Generamos el folio con la secuencia real
        DECLARE @nuevo_folio INT = NEXT VALUE FOR seq_folio_factura;
        DECLARE @factura_id INT;
        
        -- Insertamos factura con referencia cifrada
        INSERT INTO Facturas (consulta_id, total, metodo_pago, referencia_pago, folio)
        VALUES (@nueva_consulta_id, @total, @metodo_pago, ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @referencia), @nuevo_folio);
        SET @factura_id = SCOPE_IDENTITY();
        CLOSE SYMMETRIC KEY ClaveVet;

        INSERT INTO Detalle_Facturas (factura_id, concepto, cantidad, precio_unitario, subtotal)
        VALUES (@factura_id, 'Servicio Integral Veterinario', 1, @total, @total);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        INSERT INTO Registro_Errores (numero_error, mensaje_error, procedimiento)
        VALUES (ERROR_NUMBER(), ERROR_MESSAGE(), 'sp_Proceso_Completo_Consulta');
    END CATCH
END;
GO