# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models


class AuditoriaConsultas(models.Model):
    auditoria_id = models.AutoField(primary_key=True)
    consulta_id = models.IntegerField(blank=True, null=True)
    accion = models.CharField(max_length=20, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    estado_anterior = models.CharField(max_length=20, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    estado_nuevo = models.CharField(max_length=20, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    fecha_accion = models.DateTimeField(blank=True, null=True)
    usuario_bd = models.CharField(max_length=50, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Auditoria_Consultas'


class Consultas(models.Model):
    consulta_id = models.AutoField(primary_key=True)
    mascota = models.ForeignKey('Mascotas', models.DO_NOTHING)
    veterinario = models.ForeignKey('Veterinarios', models.DO_NOTHING)
    fecha_consulta = models.DateTimeField(blank=True, null=True)
    motivo = models.CharField(max_length=150, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    estado = models.CharField(max_length=20, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Consultas'


class DetalleFacturas(models.Model):
    detalle_id = models.AutoField(primary_key=True)
    factura = models.ForeignKey('Facturas', models.DO_NOTHING)
    concepto = models.CharField(max_length=100, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    cantidad = models.IntegerField(blank=True, null=True)
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Detalle_Facturas'


class Duenos(models.Model):
    dueno_id = models.AutoField(primary_key=True)
    nombre_completo = models.CharField(max_length=100, db_collation='Modern_Spanish_CI_AS')
    email = models.CharField(unique=True, max_length=100, db_collation='Modern_Spanish_CI_AS')
    telefono = models.CharField(max_length=20, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    direccion = models.CharField(max_length=150, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    tipo_documento = models.CharField(max_length=20, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    numero_documento = models.BinaryField(blank=True, null=True)
    fecha_registro = models.DateField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Duenos'


class Facturas(models.Model):
    factura_id = models.AutoField(primary_key=True)
    consulta = models.ForeignKey(Consultas, models.DO_NOTHING)
    fecha = models.DateField(blank=True, null=True)
    total = models.DecimalField(max_digits=10, decimal_places=2, blank=True, null=True)
    metodo_pago = models.CharField(max_length=30, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    referencia_pago = models.BinaryField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Facturas'


class Mascotas(models.Model):
    mascota_id = models.AutoField(primary_key=True)
    nombre = models.CharField(max_length=50, db_collation='Modern_Spanish_CI_AS')
    especie = models.CharField(max_length=50, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    raza = models.CharField(max_length=50, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    edad = models.IntegerField(blank=True, null=True)
    peso = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    dueno = models.ForeignKey(Duenos, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'Mascotas'


class RegistroErrores(models.Model):
    error_id = models.AutoField(primary_key=True)
    numero_error = models.IntegerField(blank=True, null=True)
    mensaje_error = models.CharField(max_length=500, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    procedimiento = models.CharField(max_length=100, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    fecha_error = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Registro_Errores'


class Tratamientos(models.Model):
    tratamiento_id = models.AutoField(primary_key=True)
    consulta = models.ForeignKey(Consultas, models.DO_NOTHING)
    diagnostico = models.BinaryField(blank=True, null=True)
    tratamiento = models.BinaryField(blank=True, null=True)
    observaciones = models.BinaryField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Tratamientos'


class Veterinarios(models.Model):
    veterinario_id = models.AutoField(primary_key=True)
    nombre_completo = models.CharField(max_length=100, db_collation='Modern_Spanish_CI_AS')
    especialidad = models.CharField(max_length=50, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)
    cedula_profesional = models.BinaryField(blank=True, null=True)
    usuario = models.CharField(unique=True, max_length=50, db_collation='Modern_Spanish_CI_AS')
    contrasena = models.BinaryField(blank=True, null=True)
    estado = models.CharField(max_length=20, db_collation='Modern_Spanish_CI_AS', blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'Veterinarios'
