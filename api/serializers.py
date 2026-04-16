from rest_framework import serializers
from .models import Duenos, Mascotas, Veterinarios, Consultas

class DuenoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Duenos
        fields = '__all__'

class MascotaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Mascotas
        fields = '__all__'

class VeterinarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Veterinarios
        fields = ['veterinario_id', 'nombre_completo', 'especialidad', 'usuario', 'estado'] 
        # Excluimos contrasena y cedula por seguridad

class ConsultaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Consultas
        fields = '__all__'