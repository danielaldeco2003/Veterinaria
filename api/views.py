from rest_framework import viewsets
from .models import Duenos, Mascotas, Tratamientos, Veterinarios, Consultas
from .serializers import DuenoSerializer, MascotaSerializer, VeterinarioSerializer, ConsultaSerializer
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db.models import Count
from django.db import connection

class DuenoViewSet(viewsets.ModelViewSet):
    queryset = Duenos.objects.all()
    serializer_class = DuenoSerializer

class MascotaViewSet(viewsets.ModelViewSet):
    queryset = Mascotas.objects.all()
    serializer_class = MascotaSerializer

class VeterinarioViewSet(viewsets.ModelViewSet):
    queryset = Veterinarios.objects.all()
    serializer_class = VeterinarioSerializer

class ConsultaViewSet(viewsets.ModelViewSet):
    queryset = Consultas.objects.all()
    serializer_class = ConsultaSerializer


@api_view(['GET'])
def dashboard_stats(request):
    # Contamos directo de la base de datos
    total_mascotas = Mascotas.objects.count()
    # Contamos las citas pendientes
    citas_hoy = Consultas.objects.filter(estado='Pendiente').count()
    # Contamos cuántos tratamientos hay registrados
    total_tratamientos = Tratamientos.objects.count()

    # Traemos las últimas 3 consultas para la lista
    ultimas_consultas = Consultas.objects.select_related('mascota_id').order_by('-fecha_consulta')[:3]
    consultas_data = []
    for c in ultimas_consultas:
        consultas_data.append({
            "hora": c.fecha_consulta.strftime("%I:%M %p"),
            "mascota": c.mascota_id.nombre,
            "motivo": c.motivo
        })

    return Response({
        "total_mascotas": total_mascotas,
        "citas_hoy": citas_hoy,
        "total_tratamientos": total_tratamientos,
        "proximas_citas": consultas_data
    })




@api_view(['POST'])
def login_veterinario(request):
    usuario = request.data.get('usuario')
    contrasena = request.data.get('contrasena')

    with connection.cursor() as cursor:
        # Aquí está la magia corregida: usamos CertificadoVet y ClaveVet
        cursor.execute("""
            OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;
            
            SELECT veterinario_id, nombre_completo, especialidad 
            FROM Veterinarios 
            WHERE usuario = %s AND CONVERT(varchar, DECRYPTBYKEY(contrasena)) = %s;
            
            CLOSE SYMMETRIC KEY ClaveVet;
        """, [usuario, contrasena])
        
        row = cursor.fetchone()

    if row:
        return Response({
            "veterinario_id": row[0],
            "nombre_completo": row[1],
            "especialidad": row[2]
        })
    else:
        return Response({"error": "Usuario o contraseña incorrectos"}, status=400)
    


    # Agrega esta función de ayuda arriba de tu nueva vista
def dictfetchall(cursor):
    "Devuelve todas las filas de un cursor como un diccionario"
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]

@api_view(['GET'])
def reportes_avanzados(request):
    with connection.cursor() as cursor:
        # Jalamos el Ranking de Veterinarios
        cursor.execute("SELECT ranking, veterinario, especialidad, total_consultas FROM vw_ranking_veterinarios")
        ranking = dictfetchall(cursor)
        
        # Jalamos la Clasificación de Clientes (CASE)
        cursor.execute("SELECT dueno, total_consultas, categoria FROM vw_clientes_frecuentes")
        clientes = dictfetchall(cursor)
        
    return Response({
        "ranking": ranking,
        "clientes": clientes
    })



@api_view(['GET'])
def historial_medico(request, vet_id):
    with connection.cursor() as cursor:
        # Abrimos la bóveda para desencriptar
        cursor.execute("""
            OPEN SYMMETRIC KEY ClaveVet DECRYPTION BY CERTIFICATE CertificadoVet;

            SELECT 
                c.consulta_id,
                c.fecha_consulta,
                c.motivo,
                c.estado,
                m.mascota_id,
                m.nombre AS mascota_nombre,
                m.especie,
                m.raza,
                d.nombre_completo AS dueno_nombre,
                d.telefono AS dueno_telefono,
                -- ¡AQUÍ ESTÁ LA MAGIA! Desencriptamos lo que le hicieron
                CONVERT(varchar, DECRYPTBYKEY(t.diagnostico)) AS diagnostico,
                CONVERT(varchar, DECRYPTBYKEY(t.tratamiento)) AS tratamiento
            FROM Consultas c
            INNER JOIN Mascotas m ON c.mascota_id = m.mascota_id
            INNER JOIN Duenos d ON m.dueno_id = d.dueno_id
            LEFT JOIN Tratamientos t ON c.consulta_id = t.consulta_id
            WHERE c.veterinario_id = %s
            ORDER BY c.fecha_consulta DESC;

            CLOSE SYMMETRIC KEY ClaveVet;
        """, [vet_id])
        
        historial = dictfetchall(cursor)
        
    return Response(historial)


@api_view(['POST'])
def registrar_dueno_seguro(request):
    # Esto demuestra el uso de Procedimientos Almacenados y Cifrado (Requisito 3 y 9)
    data = request.data
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                EXEC sp_registrar_dueno %s, %s, %s, %s, %s, %s
            """, [
                data['nombre_completo'], data['email'], data['telefono'], 
                data['direccion'], data['tipo_documento'], data['numero_documento']
            ])
        return Response({"mensaje": "Dueño registrado y cifrado en BD con éxito"})
    except Exception as e:
        return Response({"error": str(e)}, status=400)

@api_view(['GET'])
def panel_auditoria_facturas(request):
    # Esto demuestra Auditoría, TRY/CATCH, PIVOT y Facturación (Requisitos 1, 4, 6, 8)
    with connection.cursor() as cursor:
        cursor.execute("SELECT auditoria_id, consulta_id, accion, estado_anterior, estado_nuevo, fecha_accion, usuario_bd FROM Auditoria_Consultas ORDER BY fecha_accion DESC")
        auditoria = dictfetchall(cursor)
        
        cursor.execute("SELECT error_id, numero_error, mensaje_error, procedimiento, fecha_error FROM Registro_Errores ORDER BY fecha_error DESC")
        errores = dictfetchall(cursor)
        
        cursor.execute("SELECT * FROM vw_consultas_por_mes") # El famoso PIVOT
        pivot = dictfetchall(cursor)
        
        cursor.execute("""
            SELECT f.factura_id, f.fecha, f.total, f.metodo_pago, c.motivo 
            FROM Facturas f 
            JOIN Consultas c ON f.consulta_id = c.consulta_id 
            ORDER BY f.fecha DESC
        """)
        facturas = dictfetchall(cursor)
        
    return Response({
        "auditoria": auditoria,
        "errores": errores,
        "pivot": pivot,
        "facturas": facturas
    })

@api_view(['POST'])
def registrar_consulta_completa(request):
    data = request.data
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                EXEC sp_Proceso_Completo_Consulta 
                @mascota_id=%s, @veterinario_id=%s, @motivo=%s, 
                @diagnostico=%s, @tratamiento=%s, @total=%s, 
                @metodo_pago=%s, @referencia=%s
            """, [
                data['mascota_id'], data['veterinario_id'], data['motivo'],
                data['diagnostico'], data['tratamiento'], data['total'],
                data['metodo_pago'], data['referencia']
            ])
        return Response({"mensaje": "Transacción completa ejecutada con éxito"})
    except Exception as e:
        return Response({"error": str(e)}, status=400)