USE ClinicaVeterinaria;
GO

IF COL_LENGTH('dbo.Veterinarios', 'rol') IS NULL
BEGIN
    ALTER TABLE dbo.Veterinarios
    ADD rol VARCHAR(20) NOT NULL
        CONSTRAINT DF_Veterinarios_Rol DEFAULT 'Veterinario';
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'CK_Veterinarios_Rol'
)
BEGIN
    ALTER TABLE dbo.Veterinarios
    ADD CONSTRAINT CK_Veterinarios_Rol
    CHECK (rol IN ('Administrador', 'Veterinario', 'Recepcionista'));
END
GO

UPDATE dbo.Veterinarios
SET rol = 'Veterinario'
WHERE rol IS NULL OR rol = '';
GO

OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;

IF NOT EXISTS (SELECT 1 FROM dbo.Veterinarios WHERE usuario = 'admin')
BEGIN
    INSERT INTO dbo.Veterinarios
    (
        nombre_completo,
        especialidad,
        cedula_profesional,
        usuario,
        contrasena,
        estado,
        rol
    )
    VALUES
    (
        'Administrador del Sistema',
        'Administracion',
        NULL,
        'admin',
        ENCRYPTBYKEY(KEY_GUID('ClaveVet'), 'admin123'),
        'Activo',
        'Administrador'
    );
END

IF NOT EXISTS (SELECT 1 FROM dbo.Veterinarios WHERE usuario = 'recepcion')
BEGIN
    INSERT INTO dbo.Veterinarios
    (
        nombre_completo,
        especialidad,
        cedula_profesional,
        usuario,
        contrasena,
        estado,
        rol
    )
    VALUES
    (
        'Recepcion Principal',
        'Recepcion',
        NULL,
        'recepcion',
        ENCRYPTBYKEY(KEY_GUID('ClaveVet'), 'recep123'),
        'Activo',
        'Recepcionista'
    );
END

CLOSE SYMMETRIC KEY ClaveVet;
GO