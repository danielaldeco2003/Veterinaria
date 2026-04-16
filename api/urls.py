from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DuenoViewSet, MascotaViewSet, VeterinarioViewSet, ConsultaViewSet, dashboard_stats, historial_medico, login_veterinario, panel_auditoria_facturas, registrar_consulta_completa, registrar_dueno_seguro, reportes_avanzados

router = DefaultRouter()
router.register(r'duenos', DuenoViewSet)
router.register(r'mascotas', MascotaViewSet)
router.register(r'veterinarios', VeterinarioViewSet)
router.register(r'consultas', ConsultaViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('dashboard-stats/', dashboard_stats, name='dashboard-stats'),
    path('login/', login_veterinario, name='login-veterinario'),
    path('reportes/', reportes_avanzados, name='reportes'),
    path('historial/<int:vet_id>/', historial_medico, name='historial'),
    path('registrar-dueno/', registrar_dueno_seguro),
    path('auditoria-facturas/', panel_auditoria_facturas),
    path('nueva-consulta/', registrar_consulta_completa),
]