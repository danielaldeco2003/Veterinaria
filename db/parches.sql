USE ClinicaVeterinaria;
GO

/* =========================================================
   COMPLEMENTO SIN REHACER TU ESTRUCTURA
   ========================================================= */

SET NOCOUNT ON;
GO

/* =========================================================
   1) FORTALECER TABLA DE ERRORES
   ========================================================= */
IF COL_LENGTH('dbo.Registro_Errores', 'severidad') IS NULL
    ALTER TABLE dbo.Registro_Errores ADD severidad INT NULL;
GO
IF COL_LENGTH('dbo.Registro_Errores', 'estado_error') IS NULL
    ALTER TABLE dbo.Registro_Errores ADD estado_error INT NULL;
GO
IF COL_LENGTH('dbo.Registro_Errores', 'linea_error') IS NULL
    ALTER TABLE dbo.Registro_Errores ADD linea_error INT NULL;
GO

/* =========================================================
   2) VALIDACIONES EN BD (CHECKS)
   ========================================================= */
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Mascotas_Edad')
BEGIN
    ALTER TABLE dbo.Mascotas
    ADD CONSTRAINT CK_Mascotas_Edad
    CHECK (edad IS NULL OR edad >= 0);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Mascotas_Peso')
BEGIN
    ALTER TABLE dbo.Mascotas
    ADD CONSTRAINT CK_Mascotas_Peso
    CHECK (peso IS NULL OR peso > 0);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Veterinarios_Estado')
BEGIN
    ALTER TABLE dbo.Veterinarios
    ADD CONSTRAINT CK_Veterinarios_Estado
    CHECK (estado IN ('Activo', 'Inactivo'));
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Consultas_Estado')
BEGIN
    ALTER TABLE dbo.Consultas
    ADD CONSTRAINT CK_Consultas_Estado
    CHECK (estado IN ('Pendiente', 'Atendida', 'Cancelada'));
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Facturas_Total')
BEGIN
    ALTER TABLE dbo.Facturas
    ADD CONSTRAINT CK_Facturas_Total
    CHECK (total IS NULL OR total >= 0);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DetalleFacturas_Cantidad')
BEGIN
    ALTER TABLE dbo.Detalle_Facturas
    ADD CONSTRAINT CK_DetalleFacturas_Cantidad
    CHECK (cantidad IS NULL OR cantidad > 0);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DetalleFacturas_Precio')
BEGIN
    ALTER TABLE dbo.Detalle_Facturas
    ADD CONSTRAINT CK_DetalleFacturas_Precio
    CHECK (precio_unitario IS NULL OR precio_unitario >= 0);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_DetalleFacturas_Subtotal')
BEGIN
    ALTER TABLE dbo.Detalle_Facturas
    ADD CONSTRAINT CK_DetalleFacturas_Subtotal
    CHECK (subtotal IS NULL OR subtotal >= 0);
END;
GO

/* =========================================================
   3) ÍNDICES COMPLEMENTARIOS
   ========================================================= */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'idx_mascotas_dueno'
      AND object_id = OBJECT_ID('dbo.Mascotas')
)
CREATE INDEX idx_mascotas_dueno ON dbo.Mascotas(dueno_id);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'idx_consultas_veterinario'
      AND object_id = OBJECT_ID('dbo.Consultas')
)
CREATE INDEX idx_consultas_veterinario ON dbo.Consultas(veterinario_id);
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'idx_facturas_fecha'
      AND object_id = OBJECT_ID('dbo.Facturas')
)
CREATE INDEX idx_facturas_fecha ON dbo.Facturas(fecha);
GO

/* =========================================================
   4) FOLIO DE FACTURAS BIEN AMARRADO
   ========================================================= */
IF COL_LENGTH('dbo.Facturas', 'folio') IS NULL
BEGIN
    ALTER TABLE dbo.Facturas ADD folio INT NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.sequences
    WHERE name = 'seq_folio_factura'
      AND SCHEMA_NAME(schema_id) = 'dbo'
)
BEGIN
    CREATE SEQUENCE dbo.seq_folio_factura
        START WITH 1000
        INCREMENT BY 1;
END;
GO

UPDATE dbo.Facturas
SET folio = NEXT VALUE FOR dbo.seq_folio_factura
WHERE folio IS NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.default_constraints
    WHERE name = 'DF_Facturas_Folio'
)
BEGIN
    ALTER TABLE dbo.Facturas
    ADD CONSTRAINT DF_Facturas_Folio
    DEFAULT (NEXT VALUE FOR dbo.seq_folio_factura) FOR folio;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'UX_Facturas_Folio'
      AND object_id = OBJECT_ID('dbo.Facturas')
)
BEGIN
    CREATE UNIQUE INDEX UX_Facturas_Folio
    ON dbo.Facturas(folio)
    WHERE folio IS NOT NULL;
END;
GO

/* =========================================================
   5) COMPLETAR AUDITORÍAS NO CENTRALIZADAS
   ========================================================= */

-- Auditoria_Consultas: ampliar columnas
IF COL_LENGTH('dbo.Auditoria_Consultas', 'datos_anteriores') IS NULL
    ALTER TABLE dbo.Auditoria_Consultas ADD datos_anteriores NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.Auditoria_Consultas', 'datos_nuevos') IS NULL
    ALTER TABLE dbo.Auditoria_Consultas ADD datos_nuevos NVARCHAR(MAX) NULL;
GO

-- Auditoria_Tratamientos
IF OBJECT_ID('dbo.Auditoria_Tratamientos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Auditoria_Tratamientos (
        auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
        tratamiento_id INT,
        consulta_id INT,
        accion VARCHAR(20),
        datos_anteriores NVARCHAR(MAX),
        datos_nuevos NVARCHAR(MAX),
        fecha_accion DATETIME DEFAULT GETDATE(),
        usuario_bd VARCHAR(50) DEFAULT SYSTEM_USER
    );
END;
GO

-- Auditoria_Facturas
IF OBJECT_ID('dbo.Auditoria_Facturas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Auditoria_Facturas (
        auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
        factura_id INT,
        consulta_id INT,
        accion VARCHAR(20),
        total_registrado DECIMAL(10,2),
        total_anterior DECIMAL(10,2),
        total_nuevo DECIMAL(10,2),
        datos_anteriores NVARCHAR(MAX),
        datos_nuevos NVARCHAR(MAX),
        fecha_accion DATETIME DEFAULT GETDATE(),
        usuario_bd VARCHAR(50) DEFAULT SYSTEM_USER
    );
END;
GO

IF COL_LENGTH('dbo.Auditoria_Facturas', 'consulta_id') IS NULL
    ALTER TABLE dbo.Auditoria_Facturas ADD consulta_id INT NULL;
GO
IF COL_LENGTH('dbo.Auditoria_Facturas', 'total_anterior') IS NULL
    ALTER TABLE dbo.Auditoria_Facturas ADD total_anterior DECIMAL(10,2) NULL;
GO
IF COL_LENGTH('dbo.Auditoria_Facturas', 'total_nuevo') IS NULL
    ALTER TABLE dbo.Auditoria_Facturas ADD total_nuevo DECIMAL(10,2) NULL;
GO
IF COL_LENGTH('dbo.Auditoria_Facturas', 'datos_anteriores') IS NULL
    ALTER TABLE dbo.Auditoria_Facturas ADD datos_anteriores NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.Auditoria_Facturas', 'datos_nuevos') IS NULL
    ALTER TABLE dbo.Auditoria_Facturas ADD datos_nuevos NVARCHAR(MAX) NULL;
GO

/* =========================================================
   6) TRIGGERS DE AUDITORÍA COMPLETA
   ========================================================= */

CREATE OR ALTER TRIGGER dbo.trg_Audit_Consultas
ON dbo.Consultas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Auditoria_Consultas
    (
        consulta_id,
        accion,
        estado_anterior,
        estado_nuevo,
        datos_anteriores,
        datos_nuevos
    )
    SELECT
        COALESCE(i.consulta_id, d.consulta_id) AS consulta_id,
        CASE
            WHEN d.consulta_id IS NULL THEN 'INSERT'
            WHEN i.consulta_id IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END AS accion,
        d.estado AS estado_anterior,
        i.estado AS estado_nuevo,
        (
            SELECT
                d.consulta_id,
                d.mascota_id,
                d.veterinario_id,
                d.fecha_consulta,
                d.motivo,
                d.estado
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS datos_anteriores,
        (
            SELECT
                i.consulta_id,
                i.mascota_id,
                i.veterinario_id,
                i.fecha_consulta,
                i.motivo,
                i.estado
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS datos_nuevos
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON i.consulta_id = d.consulta_id;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Audit_Tratamientos
ON dbo.Tratamientos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Auditoria_Tratamientos
    (
        tratamiento_id,
        consulta_id,
        accion,
        datos_anteriores,
        datos_nuevos
    )
    SELECT
        COALESCE(i.tratamiento_id, d.tratamiento_id) AS tratamiento_id,
        COALESCE(i.consulta_id, d.consulta_id) AS consulta_id,
        CASE
            WHEN d.tratamiento_id IS NULL THEN 'INSERT'
            WHEN i.tratamiento_id IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END AS accion,
        (
            SELECT
                d.tratamiento_id,
                d.consulta_id
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS datos_anteriores,
        (
            SELECT
                i.tratamiento_id,
                i.consulta_id
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS datos_nuevos
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON i.tratamiento_id = d.tratamiento_id;
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_Audit_Facturas
ON dbo.Facturas
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Auditoria_Facturas
    (
        factura_id,
        consulta_id,
        accion,
        total_registrado,
        total_anterior,
        total_nuevo,
        datos_anteriores,
        datos_nuevos
    )
    SELECT
        COALESCE(i.factura_id, d.factura_id) AS factura_id,
        COALESCE(i.consulta_id, d.consulta_id) AS consulta_id,
        CASE
            WHEN d.factura_id IS NULL THEN 'INSERT'
            WHEN i.factura_id IS NULL THEN 'DELETE'
            ELSE 'UPDATE'
        END AS accion,
        COALESCE(i.total, d.total) AS total_registrado,
        d.total AS total_anterior,
        i.total AS total_nuevo,
        (
            SELECT
                d.factura_id,
                d.consulta_id,
                d.fecha,
                d.total,
                d.metodo_pago,
                d.folio
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS datos_anteriores,
        (
            SELECT
                i.factura_id,
                i.consulta_id,
                i.fecha,
                i.total,
                i.metodo_pago,
                i.folio
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ) AS datos_nuevos
    FROM inserted i
    FULL OUTER JOIN deleted d
        ON i.factura_id = d.factura_id;
END;
GO

/* =========================================================
   7) TRIGGER DE NEGOCIO: ESTADO AUTOMÁTICO
   ========================================================= */
CREATE OR ALTER TRIGGER dbo.trg_Estado_Consulta_Atendida
ON dbo.Tratamientos
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET c.estado = 'Atendida'
    FROM dbo.Consultas c
    INNER JOIN inserted i
        ON c.consulta_id = i.consulta_id
    WHERE c.estado <> 'Atendida';
END;
GO

/* =========================================================
   8) PROCEDIMIENTO: REGISTRAR DUEÑO (ROBUSTO)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_Registrar_Dueno
    @nombre VARCHAR(100),
    @email VARCHAR(100),
    @tel VARCHAR(20),
    @dir VARCHAR(150),
    @tipo_doc VARCHAR(20),
    @num_doc VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.Duenos WHERE email = @email)
            THROW 50001, 'El email del dueño ya existe.', 1;

        OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;

        INSERT INTO dbo.Duenos
        (
            nombre_completo,
            email,
            telefono,
            direccion,
            tipo_documento,
            numero_documento
        )
        VALUES
        (
            @nombre,
            @email,
            @tel,
            @dir,
            @tipo_doc,
            ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @num_doc)
        );

        CLOSE SYMMETRIC KEY ClaveVet;

        SELECT SCOPE_IDENTITY() AS dueno_id;
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'ClaveVet')
            CLOSE SYMMETRIC KEY ClaveVet;

        INSERT INTO dbo.Registro_Errores
        (
            numero_error,
            mensaje_error,
            procedimiento,
            severidad,
            estado_error,
            linea_error
        )
        VALUES
        (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            'sp_Registrar_Dueno',
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_LINE()
        );

        THROW;
    END CATCH
END;
GO

/* =========================================================
   9) PROCEDIMIENTO: REGISTRAR CONSULTA
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_Registrar_Consulta
    @mascota_id INT,
    @veterinario_id INT,
    @motivo VARCHAR(150),
    @estado VARCHAR(20) = 'Pendiente'
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.Mascotas WHERE mascota_id = @mascota_id)
            THROW 50002, 'La mascota no existe.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Veterinarios
            WHERE veterinario_id = @veterinario_id
              AND estado = 'Activo'
        )
            THROW 50003, 'El veterinario no existe o está inactivo.', 1;

        INSERT INTO dbo.Consultas
        (
            mascota_id,
            veterinario_id,
            motivo,
            estado
        )
        VALUES
        (
            @mascota_id,
            @veterinario_id,
            @motivo,
            @estado
        );

        COMMIT TRANSACTION;

        SELECT SCOPE_IDENTITY() AS consulta_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        INSERT INTO dbo.Registro_Errores
        (
            numero_error,
            mensaje_error,
            procedimiento,
            severidad,
            estado_error,
            linea_error
        )
        VALUES
        (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            'sp_Registrar_Consulta',
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_LINE()
        );

        THROW;
    END CATCH
END;
GO

/* =========================================================
   10) PROCEDIMIENTO: GENERAR TRATAMIENTO CIFRADO
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_Generar_Tratamiento_Cifrado
    @consulta_id INT,
    @diagnostico VARCHAR(500),
    @tratamiento VARCHAR(500),
    @observaciones VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.Consultas WHERE consulta_id = @consulta_id)
            THROW 50004, 'La consulta no existe.', 1;

        OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;

        INSERT INTO dbo.Tratamientos
        (
            consulta_id,
            diagnostico,
            tratamiento,
            observaciones
        )
        VALUES
        (
            @consulta_id,
            ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @diagnostico),
            ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @tratamiento),
            ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @observaciones)
        );

        CLOSE SYMMETRIC KEY ClaveVet;

        COMMIT TRANSACTION;

        SELECT SCOPE_IDENTITY() AS tratamiento_id;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'ClaveVet')
            CLOSE SYMMETRIC KEY ClaveVet;

        INSERT INTO dbo.Registro_Errores
        (
            numero_error,
            mensaje_error,
            procedimiento,
            severidad,
            estado_error,
            linea_error
        )
        VALUES
        (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            'sp_Generar_Tratamiento_Cifrado',
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_LINE()
        );

        THROW;
    END CATCH
END;
GO

/* =========================================================
   11) PROCEDIMIENTO TRANSACCIONAL COMPLETO CORREGIDO
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_Proceso_Completo_Consulta
    @mascota_id INT,
    @veterinario_id INT,
    @motivo VARCHAR(150),
    @diagnostico VARCHAR(500),
    @tratamiento VARCHAR(500),
    @observaciones VARCHAR(500) = NULL,
    @total DECIMAL(10,2),
    @metodo_pago VARCHAR(30),
    @referencia VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.Mascotas WHERE mascota_id = @mascota_id)
            THROW 50005, 'La mascota no existe.', 1;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.Veterinarios
            WHERE veterinario_id = @veterinario_id
              AND estado = 'Activo'
        )
            THROW 50006, 'El veterinario no existe o está inactivo.', 1;

        DECLARE @nueva_consulta_id INT;
        DECLARE @factura_id INT;
        DECLARE @nuevo_folio INT;

        INSERT INTO dbo.Consultas
        (
            mascota_id,
            veterinario_id,
            motivo,
            estado
        )
        VALUES
        (
            @mascota_id,
            @veterinario_id,
            @motivo,
            'Pendiente'
        );

        SET @nueva_consulta_id = SCOPE_IDENTITY();

        OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;

        INSERT INTO dbo.Tratamientos
        (
            consulta_id,
            diagnostico,
            tratamiento,
            observaciones
        )
        VALUES
        (
            @nueva_consulta_id,
            ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @diagnostico),
            ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @tratamiento),
            ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @observaciones)
        );

        SET @nuevo_folio = NEXT VALUE FOR dbo.seq_folio_factura;

        INSERT INTO dbo.Facturas
        (
            consulta_id,
            total,
            metodo_pago,
            referencia_pago,
            folio
        )
        VALUES
        (
            @nueva_consulta_id,
            @total,
            @metodo_pago,
            CASE
                WHEN @referencia IS NULL THEN NULL
                ELSE ENCRYPTBYKEY(KEY_GUID('ClaveVet'), @referencia)
            END,
            @nuevo_folio
        );

        SET @factura_id = SCOPE_IDENTITY();

        CLOSE SYMMETRIC KEY ClaveVet;

        INSERT INTO dbo.Detalle_Facturas
        (
            factura_id,
            concepto,
            cantidad,
            precio_unitario,
            subtotal
        )
        VALUES
        (
            @factura_id,
            'Servicio Integral Veterinario',
            1,
            @total,
            @total
        );

        COMMIT TRANSACTION;

        SELECT
            @nueva_consulta_id AS consulta_id,
            @factura_id AS factura_id,
            @nuevo_folio AS folio;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'ClaveVet')
            CLOSE SYMMETRIC KEY ClaveVet;

        INSERT INTO dbo.Registro_Errores
        (
            numero_error,
            mensaje_error,
            procedimiento,
            severidad,
            estado_error,
            linea_error
        )
        VALUES
        (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            'sp_Proceso_Completo_Consulta',
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_LINE()
        );

        THROW;
    END CATCH
END;
GO

/* =========================================================
   12) PROCEDIMIENTO: REPORTE DE CONSULTAS POR VETERINARIO
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_Reporte_Consultas_Por_Veterinario
    @fecha_inicio DATE = NULL,
    @fecha_fin DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        v.veterinario_id,
        v.nombre_completo AS veterinario,
        v.especialidad,
        COUNT(c.consulta_id) AS total_consultas,
        SUM(CASE WHEN c.estado = 'Atendida' THEN 1 ELSE 0 END) AS atendidas,
        SUM(CASE WHEN c.estado = 'Cancelada' THEN 1 ELSE 0 END) AS canceladas,
        ISNULL(SUM(f.total), 0) AS total_facturado
    FROM dbo.Veterinarios v
    LEFT JOIN dbo.Consultas c
        ON v.veterinario_id = c.veterinario_id
       AND (@fecha_inicio IS NULL OR CAST(c.fecha_consulta AS DATE) >= @fecha_inicio)
       AND (@fecha_fin IS NULL OR CAST(c.fecha_consulta AS DATE) <= @fecha_fin)
    LEFT JOIN dbo.Facturas f
        ON c.consulta_id = f.consulta_id
    GROUP BY
        v.veterinario_id,
        v.nombre_completo,
        v.especialidad
    ORDER BY total_consultas DESC, veterinario;
END;
GO

/* =========================================================
   13) EVIDENCIA DE DECRYPTBYKEY
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.sp_Evidencia_Cifrado
    @dueno_id INT = NULL,
    @consulta_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;

        SELECT
            d.dueno_id,
            d.nombre_completo,
            d.email,
            d.tipo_documento,
            CONVERT(VARCHAR(100), DECRYPTBYKEY(d.numero_documento)) AS numero_documento_descifrado
        FROM dbo.Duenos d
        WHERE @dueno_id IS NULL OR d.dueno_id = @dueno_id;

        SELECT
            c.consulta_id,
            m.nombre AS mascota,
            CONVERT(VARCHAR(500), DECRYPTBYKEY(t.diagnostico)) AS diagnostico_descifrado,
            CONVERT(VARCHAR(500), DECRYPTBYKEY(t.tratamiento)) AS tratamiento_descifrado,
            CONVERT(VARCHAR(500), DECRYPTBYKEY(t.observaciones)) AS observaciones_descifradas
        FROM dbo.Tratamientos t
        INNER JOIN dbo.Consultas c
            ON t.consulta_id = c.consulta_id
        INNER JOIN dbo.Mascotas m
            ON c.mascota_id = m.mascota_id
        WHERE @consulta_id IS NULL OR c.consulta_id = @consulta_id;

        SELECT
            f.factura_id,
            f.folio,
            f.metodo_pago,
            CONVERT(VARCHAR(100), DECRYPTBYKEY(f.referencia_pago)) AS referencia_pago_descifrada
        FROM dbo.Facturas f
        WHERE @consulta_id IS NULL OR f.consulta_id = @consulta_id;

        CLOSE SYMMETRIC KEY ClaveVet;
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM sys.openkeys WHERE key_name = 'ClaveVet')
            CLOSE SYMMETRIC KEY ClaveVet;

        INSERT INTO dbo.Registro_Errores
        (
            numero_error,
            mensaje_error,
            procedimiento,
            severidad,
            estado_error,
            linea_error
        )
        VALUES
        (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            'sp_Evidencia_Cifrado',
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_LINE()
        );

        THROW;
    END CATCH
END;
GO

/* =========================================================
   14) VISTA QUE TU DJANGO NECESITA
   ========================================================= */
CREATE OR ALTER VIEW dbo.vw_clientes_frecuentes
AS
SELECT
    d.nombre_completo AS dueno,
    COUNT(c.consulta_id) AS total_consultas,
    CASE
        WHEN COUNT(c.consulta_id) >= 5 THEN 'Cliente VIP'
        WHEN COUNT(c.consulta_id) BETWEEN 2 AND 4 THEN 'Cliente Frecuente'
        ELSE 'Cliente Nuevo'
    END AS categoria
FROM dbo.Duenos d
LEFT JOIN dbo.Mascotas m
    ON d.dueno_id = m.dueno_id
LEFT JOIN dbo.Consultas c
    ON m.mascota_id = c.mascota_id
GROUP BY
    d.dueno_id,
    d.nombre_completo;
GO

/* =========================================================
   15) VISTA DE JOINS COMPLETOS DEL SISTEMA
   ========================================================= */
CREATE OR ALTER VIEW dbo.vw_Consultas_Detalle_Completo
AS
SELECT
    c.consulta_id,
    c.fecha_consulta,
    c.estado,
    c.motivo,
    d.dueno_id,
    d.nombre_completo AS dueno,
    m.mascota_id,
    m.nombre AS mascota,
    m.especie,
    m.raza,
    v.veterinario_id,
    v.nombre_completo AS veterinario,
    v.especialidad,
    f.factura_id,
    f.folio,
    f.fecha AS fecha_factura,
    f.total,
    f.metodo_pago,
    df.detalle_id,
    df.concepto,
    df.cantidad,
    df.precio_unitario,
    df.subtotal
FROM dbo.Consultas c
INNER JOIN dbo.Mascotas m
    ON c.mascota_id = m.mascota_id
INNER JOIN dbo.Duenos d
    ON m.dueno_id = d.dueno_id
INNER JOIN dbo.Veterinarios v
    ON c.veterinario_id = v.veterinario_id
LEFT JOIN dbo.Facturas f
    ON c.consulta_id = f.consulta_id
LEFT JOIN dbo.Detalle_Facturas df
    ON f.factura_id = df.factura_id;
GO

/* =========================================================
   16) ROLES DE BASE DE DATOS PARA EVIDENCIA ACADÉMICA
   ========================================================= */
IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'Administrador' AND type = 'R'
)
CREATE ROLE Administrador;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'Veterinario' AND type = 'R'
)
CREATE ROLE Veterinario;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.database_principals
    WHERE name = 'Recepcionista' AND type = 'R'
)
CREATE ROLE Recepcionista;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO Administrador;
GRANT EXECUTE ON SCHEMA::dbo TO Administrador;
GO

GRANT SELECT ON dbo.Duenos TO Recepcionista;
GRANT INSERT, UPDATE ON dbo.Duenos TO Recepcionista;
GRANT SELECT ON dbo.Mascotas TO Recepcionista;
GRANT INSERT, UPDATE ON dbo.Mascotas TO Recepcionista;
GRANT SELECT ON dbo.Consultas TO Recepcionista;
GRANT INSERT, UPDATE ON dbo.Consultas TO Recepcionista;
GRANT SELECT ON dbo.Facturas TO Recepcionista;
GRANT INSERT, UPDATE ON dbo.Facturas TO Recepcionista;
GRANT SELECT ON dbo.Detalle_Facturas TO Recepcionista;
GRANT INSERT, UPDATE ON dbo.Detalle_Facturas TO Recepcionista;
GRANT EXECUTE ON dbo.sp_Registrar_Dueno TO Recepcionista;
GRANT EXECUTE ON dbo.sp_Registrar_Consulta TO Recepcionista;
GRANT EXECUTE ON dbo.sp_Proceso_Completo_Consulta TO Recepcionista;
GO

GRANT SELECT ON dbo.Consultas TO Veterinario;
GRANT INSERT, UPDATE ON dbo.Consultas TO Veterinario;
GRANT SELECT ON dbo.Tratamientos TO Veterinario;
GRANT INSERT, UPDATE ON dbo.Tratamientos TO Veterinario;
GRANT SELECT ON dbo.Mascotas TO Veterinario;
GRANT SELECT ON dbo.Duenos TO Veterinario;
GRANT EXECUTE ON dbo.sp_Registrar_Consulta TO Veterinario;
GRANT EXECUTE ON dbo.sp_Generar_Tratamiento_Cifrado TO Veterinario;
GRANT EXECUTE ON dbo.sp_Reporte_Consultas_Por_Veterinario TO Veterinario;
GO