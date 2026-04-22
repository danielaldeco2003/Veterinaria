from rest_framework import serializers
from .models import Duenos, Mascotas, Veterinarios, Consultas


class DuenoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Duenos
        fields = '__all__'


class MascotaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mascotas
        fields = ['mascota_id', 'nombre', 'especie', 'raza', 'edad', 'peso', 'dueno']

    def validate_nombre(self, value):
        value = (value or '').strip()
        if len(value) < 2:
            raise serializers.ValidationError('El nombre debe tener al menos 2 caracteres.')
        return value

    def validate_especie(self, value):
        if value is None:
            return value
        value = value.strip()
        if not value:
            raise serializers.ValidationError('La especie no puede ir vacía.')
        return value

    def validate_raza(self, value):
        if value is None:
            return value
        value = value.strip()
        if not value:
            raise serializers.ValidationError('La raza no puede ir vacía.')
        return value

    def validate_edad(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError('La edad no puede ser negativa.')
        return value

    def validate_peso(self, value):
        if value is not None and value <= 0:
            raise serializers.ValidationError('El peso debe ser mayor que cero.')
        return value


class VeterinarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Veterinarios
        fields = ['veterinario_id', 'nombre_completo', 'especialidad', 'usuario', 'estado']


class ConsultaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Consultas
        fields = '__all__'