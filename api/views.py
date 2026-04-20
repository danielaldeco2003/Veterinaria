from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db import connection

from .models import Duenos, Mascotas, Tratamientos, Veterinarios, Consultas
from .serializers import (
    DuenoSerializer,
    MascotaSerializer,
    VeterinarioSerializer,
    ConsultaSerializer
)


def dictfetchall(cursor):
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


class DuenoViewSet(viewsets.ModelViewSet):
    queryset = Duenos.objects.all().order_by('-dueno_id')
    serializer_class = DuenoSerializer


class MascotaViewSet(viewsets.ModelViewSet):
    queryset = Mascotas.objects.all().order_by('-mascota_id')
    serializer_class = MascotaSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)

        if not serializer.is_valid():
            return Response(
                {
                    "message": "Error de validación al registrar la mascota",
                    "errors": serializer.errors,
                    "received": request.data
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class VeterinarioViewSet(viewsets.ModelViewSet):
    queryset = Veterinarios.objects.all().order_by('-veterinario_id')
    serializer_class = VeterinarioSerializer


class ConsultaViewSet(viewsets.ModelViewSet):
    queryset = Consultas.objects.all().order_by('-consulta_id')
    serializer_class = ConsultaSerializer


@api_view(['GET'])
def dashboard_stats(request):
    try:
        total_mascotas = Mascotas.objects.count()
        citas_hoy = Consultas.objects.filter(estado='Pendiente').count()
        total_tratamientos = Tratamientos.objects.count()

        ultimas_consultas = Consultas.objects.order_by('-fecha_consulta')[:3]

        consultas_data = []
        for c in ultimas_consultas:
            mascota_rel = getattr(c, 'mascota', None) or getattr(c, 'mascota_id', None)

            consultas_data.append({
                "hora": c.fecha_consulta.strftime("%I:%M %p") if c.fecha_consulta else "",
                "mascota": getattr(mascota_rel, 'nombre', ''),
                "motivo": c.motivo or ""
            })

        return Response({
            "total_mascotas": total_mascotas,
            "citas_hoy": citas_hoy,
            "total_tratamientos": total_tratamientos,
            "proximas_citas": consultas_data
        })

    except Exception as e:
        return Response(
            {"error": f"Error al cargar dashboard: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def login_veterinario(request):
    usuario = request.data.get('usuario')
    contrasena = request.data.get('contrasena')

    if not usuario or not contrasena:
        return Response(
            {"error": "Usuario y contraseña son obligatorios"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                OPEN SYMMETRIC KEY ClaveVet
                DECRYPTION BY CERTIFICATE CertificadoVet;
            """)

            cursor.execute("""
                SELECT veterinario_id, nombre_completo, especialidad, rol
                FROM dbo.Veterinarios
                WHERE usuario = %s
                  AND CONVERT(VARCHAR(100), DECRYPTBYKEY(contrasena)) = %s
                  AND estado = 'Activo';
            """, [usuario, contrasena])

            row = cursor.fetchone()

            cursor.execute("CLOSE SYMMETRIC KEY ClaveVet;")

        if row:
            return Response({
                "veterinario_id": row[0],
                "nombre_completo": row[1],
                "especialidad": row[2],
                "rol": row[3],
            })

        return Response(
            {"error": "Usuario o contraseña incorrectos"},
            status=status.HTTP_400_BAD_REQUEST
        )

    except Exception as e:
        try:
            with connection.cursor() as cursor:
                cursor.execute("CLOSE SYMMETRIC KEY ClaveVet;")
        except Exception:
            pass

        return Response(
            {"error": f"Error en login: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
def reportes_avanzados(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT ranking, veterinario, especialidad, total_consultas
                FROM dbo.vw_Ranking_Veterinarios
                ORDER BY ranking, veterinario;
            """)
            ranking = dictfetchall(cursor)

            cursor.execute("""
                SELECT dueno, total_consultas, categoria
                FROM dbo.vw_clientes_frecuentes
                ORDER BY total_consultas DESC, dueno;
            """)
            clientes = dictfetchall(cursor)

        return Response({
            "ranking": ranking,
            "clientes": clientes
        })

    except Exception as e:
        return Response(
            {"error": f"Error al cargar reportes avanzados: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
def historial_medico(request, vet_id):
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                OPEN SYMMETRIC KEY ClaveVet
                DECRYPTION BY CERTIFICATE CertificadoVet;
            """)

            cursor.execute("""
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
                    CONVERT(VARCHAR(500), DECRYPTBYKEY(t.diagnostico)) AS diagnostico,
                    CONVERT(VARCHAR(500), DECRYPTBYKEY(t.tratamiento)) AS tratamiento,
                    CONVERT(VARCHAR(500), DECRYPTBYKEY(t.observaciones)) AS observaciones
                FROM dbo.Consultas c
                INNER JOIN dbo.Mascotas m ON c.mascota_id = m.mascota_id
                INNER JOIN dbo.Duenos d ON m.dueno_id = d.dueno_id
                LEFT JOIN dbo.Tratamientos t ON c.consulta_id = t.consulta_id
                WHERE c.veterinario_id = %s
                ORDER BY c.fecha_consulta DESC;
            """, [vet_id])

            historial = dictfetchall(cursor)

            cursor.execute("CLOSE SYMMETRIC KEY ClaveVet;")

        return Response(historial)

    except Exception as e:
        try:
            with connection.cursor() as cursor:
                cursor.execute("CLOSE SYMMETRIC KEY ClaveVet;")
        except Exception:
            pass

        return Response(
            {"error": f"Error al cargar historial médico: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def registrar_dueno_seguro(request):
    data = request.data

    required_fields = [
        'nombre_completo',
        'email',
        'telefono',
        'direccion',
        'tipo_documento',
        'numero_documento'
    ]

    faltantes = [campo for campo in required_fields if campo not in data or data[campo] in [None, ""]]
    if faltantes:
        return Response(
            {"error": f"Faltan campos obligatorios: {', '.join(faltantes)}"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                EXEC dbo.sp_Registrar_Dueno %s, %s, %s, %s, %s, %s
            """, [
                data['nombre_completo'],
                data['email'],
                data['telefono'],
                data['direccion'],
                data['tipo_documento'],
                data['numero_documento']
            ])

            row = cursor.fetchone()

        return Response({
            "mensaje": "Dueño registrado y cifrado en BD con éxito",
            "dueno_id": row[0] if row else None
        })

    except Exception as e:
        return Response(
            {"error": f"Error al registrar dueño: {str(e)}"},
            status=status.HTTP_400_BAD_REQUEST
        )


@api_view(['GET'])
def panel_auditoria_facturas(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT auditoria_id, consulta_id, accion, estado_anterior, estado_nuevo,
                       datos_anteriores, datos_nuevos, fecha_accion, usuario_bd
                FROM dbo.Auditoria_Consultas
                ORDER BY fecha_accion DESC;
            """)
            auditoria_consultas = dictfetchall(cursor)

            cursor.execute("""
                SELECT auditoria_id, tratamiento_id, consulta_id, accion,
                       datos_anteriores, datos_nuevos, fecha_accion, usuario_bd
                FROM dbo.Auditoria_Tratamientos
                ORDER BY fecha_accion DESC;
            """)
            auditoria_tratamientos = dictfetchall(cursor)

            cursor.execute("""
                SELECT auditoria_id, factura_id, consulta_id, accion,
                       total_registrado, total_anterior, total_nuevo,
                       datos_anteriores, datos_nuevos, fecha_accion, usuario_bd
                FROM dbo.Auditoria_Facturas
                ORDER BY fecha_accion DESC;
            """)
            auditoria_facturas = dictfetchall(cursor)

            cursor.execute("""
                SELECT error_id, numero_error, mensaje_error, procedimiento,
                       severidad, estado_error, linea_error, fecha_error
                FROM dbo.Registro_Errores
                ORDER BY fecha_error DESC;
            """)
            errores = dictfetchall(cursor)

            cursor.execute("SELECT * FROM dbo.vw_Consultas_Por_Mes;")
            pivot = dictfetchall(cursor)

            cursor.execute("""
                SELECT
                    f.factura_id,
                    f.folio,
                    f.fecha,
                    f.total,
                    f.metodo_pago,
                    c.motivo
                FROM dbo.Facturas f
                INNER JOIN dbo.Consultas c ON f.consulta_id = c.consulta_id
                ORDER BY f.fecha DESC, f.factura_id DESC;
            """)
            facturas = dictfetchall(cursor)

        return Response({
            "auditoria_consultas": auditoria_consultas,
            "auditoria_tratamientos": auditoria_tratamientos,
            "auditoria_facturas": auditoria_facturas,
            "errores": errores,
            "pivot": pivot,
            "facturas": facturas
        })

    except Exception as e:
        return Response(
            {"error": f"Error al cargar panel de auditoría: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def registrar_consulta_completa(request):
    data = request.data

    required_fields = [
        'mascota_id',
        'veterinario_id',
        'motivo',
        'diagnostico',
        'tratamiento',
        'total',
        'metodo_pago'
    ]

    faltantes = [campo for campo in required_fields if campo not in data or data[campo] in [None, ""]]
    if faltantes:
        return Response(
            {"error": f"Faltan campos obligatorios: {', '.join(faltantes)}"},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                EXEC dbo.sp_Proceso_Completo_Consulta
                    @mascota_id=%s,
                    @veterinario_id=%s,
                    @motivo=%s,
                    @diagnostico=%s,
                    @tratamiento=%s,
                    @observaciones=%s,
                    @total=%s,
                    @metodo_pago=%s,
                    @referencia=%s
            """, [
                data['mascota_id'],
                data['veterinario_id'],
                data['motivo'],
                data['diagnostico'],
                data['tratamiento'],
                data.get('observaciones'),
                data['total'],
                data['metodo_pago'],
                data.get('referencia')
            ])

            row = cursor.fetchone()

        return Response({
            "mensaje": "Transacción completa ejecutada con éxito",
            "consulta_id": row[0] if row else None,
            "factura_id": row[1] if row else None,
            "folio": row[2] if row else None
        })

    except Exception as e:
        return Response(
            {"error": f"Error al registrar consulta completa: {str(e)}"},
            status=status.HTTP_400_BAD_REQUEST
        )