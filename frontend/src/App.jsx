import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  Dog,
  Calendar,
  Users,
  BarChart3,
  LogOut,
  HeartPulse,
  Trophy,
  Star,
  Activity,
  X,
  ShieldAlert,
  Receipt,
  Stethoscope,
} from 'lucide-react';
import axios from 'axios';

function App() {
  const [user, setUser] = useState(null);
  const [activeTab, setActiveTab] = useState('dashboard');

  const isAdmin = user?.rol === 'Administrador';
  const isVet = user?.rol === 'Veterinario';
  const isRecep = user?.rol === 'Recepcionista';

  const [duenos, setDuenos] = useState([]);
  const [mascotas, setMascotas] = useState([]);
  const [historial, setHistorial] = useState([]);
  const [stats, setStats] = useState({
    total_mascotas: 0,
    citas_hoy: 0,
    total_tratamientos: 0,
    proximas_citas: [],
  });
  const [reportes, setReportes] = useState({ ranking: [], clientes: [] });

  const [datosAdmin, setDatosAdmin] = useState({
    auditoria_consultas: [],
    auditoria_tratamientos: [],
    auditoria_facturas: [],
    errores: [],
    pivot: [],
    facturas: [],
  });

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loginError, setLoginError] = useState('');

  const [showPetModal, setShowPetModal] = useState(false);
  const [showDuenoModal, setShowDuenoModal] = useState(false);
  const [showConsultaModal, setShowConsultaModal] = useState(false);

  const [newPet, setNewPet] = useState({
    nombre: '',
    especie: '',
    raza: '',
    edad: '',
    peso: '',
    dueno_id: '',
  });

  const [newDueno, setNewDueno] = useState({
    nombre_completo: '',
    email: '',
    telefono: '',
    direccion: '',
    tipo_documento: 'INE',
    numero_documento: '',
  });

  const [newConsulta, setNewConsulta] = useState({
    mascota_id: '',
    veterinario_id: '',
    motivo: '',
    diagnostico: '',
    tratamiento: '',
    observaciones: '',
    total: '',
    metodo_pago: 'Tarjeta',
    referencia: '',
  });

  const normalizeText = (text) => {
    return (text || '')
      .toString()
      .trim()
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/\s+/g, ' ')
      .replace(/-/g, ' ');
  };

  const petImageMap = {
    perro: {
      default: '/imagenes/mascotas/perro-labrador.jpg.jpeg',
      labrador: '/imagenes/mascotas/perro-labrador.jpg.jpeg',
      'labrador retriever': '/imagenes/mascotas/perro-labrador.jpg.jpeg',
      husky: '/imagenes/mascotas/perro-husky.jpg.jpeg',
      'husky siberiano': '/imagenes/mascotas/perro-husky.jpg.jpeg',
      pug: '/imagenes/mascotas/perro-pug.jpg.jpeg',
      carlino: '/imagenes/mascotas/perro-pug.jpg.jpeg',
    },
    gato: {
      default: '/imagenes/mascotas/gato-default.jpg.jpeg',
      siames: '/imagenes/mascotas/gato-default.jpg.jpeg',
      persa: '/imagenes/mascotas/gato-default.jpg.jpeg',
    },
  };

  const fallbackPetImage = '/imagenes/mascotas/perro-labrador.jpg.jpeg';

  const getPetImage = (mascota) => {
    if (!mascota) return fallbackPetImage;

    const especie = normalizeText(mascota.especie);
    const raza = normalizeText(mascota.raza);

    const especieMap = petImageMap[especie];
    if (!especieMap) return fallbackPetImage;

    return especieMap[raza] || especieMap.default || fallbackPetImage;
  };

  const hiddenEncryptedDoc = (value) => {
    if (!value) return 'Sin dato';
    return `0x${String(value).substring(0, 15)}...`;
  };

  const navItemClass = (tabName, extra = '') =>
    `flex items-center gap-3 px-6 py-3 ${
      activeTab === tabName
        ? 'bg-white/10 border-l-4 border-white font-semibold'
        : 'hover:bg-white/5 transition-colors'
    } ${extra}`;

  const loadAllData = async (currentUser) => {
    if (!currentUser) return;

    try {
      const requests = [axios.get('http://127.0.0.1:8000/api/dashboard-stats/')];

      if (
        currentUser.rol === 'Administrador' ||
        currentUser.rol === 'Recepcionista' ||
        currentUser.rol === 'Veterinario'
      ) {
        requests.push(axios.get('http://127.0.0.1:8000/api/mascotas/'));
      }

      if (currentUser.rol === 'Administrador' || currentUser.rol === 'Recepcionista') {
        requests.push(axios.get('http://127.0.0.1:8000/api/duenos/'));
        requests.push(axios.get('http://127.0.0.1:8000/api/auditoria-facturas/'));
      }

      if (currentUser.rol === 'Administrador' || currentUser.rol === 'Veterinario') {
        requests.push(
          axios.get(`http://127.0.0.1:8000/api/historial/${currentUser.veterinario_id}/`)
        );
      }

      if (currentUser.rol === 'Administrador') {
        requests.push(axios.get('http://127.0.0.1:8000/api/reportes/'));
      }

      const results = await Promise.allSettled(requests);

      setDuenos([]);
      setMascotas([]);
      setHistorial([]);
      setReportes({ ranking: [], clientes: [] });
      setDatosAdmin({
        auditoria_consultas: [],
        auditoria_tratamientos: [],
        auditoria_facturas: [],
        errores: [],
        pivot: [],
        facturas: [],
      });

      for (const result of results) {
        if (result.status !== 'fulfilled') {
          console.error('Error cargando módulo:', result.reason);
          continue;
        }

        const url = result.value.config.url;
        const data = result.value.data;

        if (url.includes('/api/dashboard-stats/')) {
          setStats(data);
        } else if (url.includes('/api/mascotas/')) {
          setMascotas(data);
        } else if (url.includes('/api/duenos/')) {
          setDuenos(data);
        } else if (url.includes('/api/historial/')) {
          setHistorial(data);
        } else if (url.includes('/api/reportes/')) {
          setReportes(data);
        } else if (url.includes('/api/auditoria-facturas/')) {
          setDatosAdmin({
            auditoria_consultas: data.auditoria_consultas || [],
            auditoria_tratamientos: data.auditoria_tratamientos || [],
            auditoria_facturas: data.auditoria_facturas || [],
            errores: data.errores || [],
            pivot: data.pivot || [],
            facturas: data.facturas || [],
          });
        }
      }
    } catch (error) {
      console.error('Error general cargando datos:', error);
    }
  };

  const handleLogin = async (e) => {
    e.preventDefault();

    try {
      const response = await axios.post('http://127.0.0.1:8000/api/login/', {
        usuario: username,
        contrasena: password,
      });

      setUser(response.data);
      setLoginError('');
      setActiveTab('dashboard');
    } catch (error) {
      console.error(error);
      setLoginError('Credenciales incorrectas. Verifica tu usuario y contraseña.');
    }
  };

  const handleAddPet = async (e) => {
    e.preventDefault();

    const payload = {
      nombre: newPet.nombre.trim(),
      especie: newPet.especie.trim(),
      raza: newPet.raza.trim(),
      edad: Number(newPet.edad),
      peso: Number(newPet.peso),
      dueno: Number(newPet.dueno_id),
    };

    console.log('PAYLOAD MASCOTA:', payload);

    try {
      const response = await axios.post(
        'http://127.0.0.1:8000/api/mascotas/',
        payload
      );

      console.log('RESPUESTA OK:', response.data);

      setMascotas((prev) => [...prev, response.data]);
      setStats((prev) => ({
        ...prev,
        total_mascotas: Number(prev.total_mascotas || 0) + 1,
      }));

      setShowPetModal(false);
      setNewPet({
        nombre: '',
        especie: '',
        raza: '',
        edad: '',
        peso: '',
        dueno_id: '',
      });

      alert('¡Mascota registrada con éxito en la Base de Datos!');
    } catch (error) {
      console.error('ERROR COMPLETO:', error);
      console.error('STATUS:', error.response?.status);
      console.error('DATA:', error.response?.data);

      const backendData = error.response?.data;

      if (backendData?.errors) {
        alert(`Error al registrar mascota:\n${JSON.stringify(backendData.errors, null, 2)}`);
      } else if (backendData?.error) {
        alert(`Error al registrar mascota:\n${backendData.error}`);
      } else if (backendData?.message) {
        alert(`Error al registrar mascota:\n${backendData.message}`);
      } else {
        alert('Error al registrar la mascota. Revisa la consola.');
      }
    }
  };

  const handleAddDueno = async (e) => {
    e.preventDefault();

    try {
      await axios.post('http://127.0.0.1:8000/api/registrar-dueno/', newDueno);
      await loadAllData(user);

      setShowDuenoModal(false);
      setNewDueno({
        nombre_completo: '',
        email: '',
        telefono: '',
        direccion: '',
        tipo_documento: 'INE',
        numero_documento: '',
      });

      alert('¡Dueño registrado! Su documento ha sido cifrado en la Base de Datos con AES_256.');
    } catch (error) {
      console.error(error);
      alert('Error al registrar el dueño. Revisa la consola.');
    }
  };

  const handleAddConsulta = async (e) => {
    e.preventDefault();

    try {
      const dataToSend = {
        mascota_id: Number(newConsulta.mascota_id),
        veterinario_id: Number(user.veterinario_id),
        motivo: newConsulta.motivo,
        diagnostico: newConsulta.diagnostico,
        tratamiento: newConsulta.tratamiento,
        observaciones: newConsulta.observaciones || null,
        total: Number(newConsulta.total),
        metodo_pago: newConsulta.metodo_pago,
        referencia: newConsulta.referencia || null,
      };

      console.log('PAYLOAD CONSULTA:', dataToSend);

      await axios.post('http://127.0.0.1:8000/api/nueva-consulta/', dataToSend);

      await loadAllData(user);

      setShowConsultaModal(false);
      setNewConsulta({
        mascota_id: '',
        veterinario_id: '',
        motivo: '',
        diagnostico: '',
        tratamiento: '',
        observaciones: '',
        total: '',
        metodo_pago: 'Tarjeta',
        referencia: '',
      });

      setActiveTab('citas');

      alert(
        '¡Transacción exitosa! Consulta, tratamiento cifrado, factura y auditoría creados correctamente.'
      );
    } catch (error) {
      console.error(error);
      console.error('ERROR CONSULTA DATA:', error.response?.data);
      alert('Error en la transacción SQL. Revisa la consola para ver el detalle.');
    }
  };

  useEffect(() => {
    if (user) {
      loadAllData(user);
    }
  }, [user]);

  const expedienteDestacado = historial.length > 0 ? historial[0] : null;

  if (!user) {
    return (
      <div className="min-h-screen bg-slate-100 flex items-center justify-center font-sans">
        <div className="bg-white p-8 rounded-xl shadow-xl w-96 border-t-4 border-brandTeal">
          <div className="flex justify-center mb-6 text-brandTeal">
            <Dog size={48} />
          </div>

          <h2 className="text-2xl font-bold text-center text-slate-800 mb-6">
            Acceso a Clínica
          </h2>

          {loginError && (
            <p className="text-red-500 text-sm mb-4 text-center">{loginError}</p>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Usuario
              </label>
              <input
                type="text"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full border rounded-lg p-2 focus:ring focus:ring-teal-200 outline-none"
                placeholder="Usuario"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">
                Contraseña
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full border rounded-lg p-2 focus:ring focus:ring-teal-200 outline-none"
                placeholder="Contraseña"
                required
              />
            </div>

            <button
              type="submit"
              className="w-full bg-brandTeal hover:bg-[#0b6d7a] text-white font-bold py-2 px-4 rounded-lg transition-colors"
            >
              Ingresar al Sistema
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen bg-[#f1f5f9] font-sans">
      <aside className="w-64 bg-brandTeal text-white flex flex-col shadow-xl z-10 overflow-y-auto">
        <div className="p-6 flex items-center gap-3 border-b border-white/20">
          <Dog size={32} />
          <div>
            <h1 className="font-bold text-lg leading-tight">Veterinaria</h1>
            <p className="text-sm opacity-80">San Martín</p>
          </div>
        </div>

        <nav className="flex-1 py-4 text-sm">
          <button
            onClick={() => setActiveTab('dashboard')}
            className={navItemClass('dashboard', 'w-full text-left')}
          >
            <LayoutDashboard size={20} /> Dashboard
          </button>

          {(isAdmin || isRecep) && (
            <>
              <button
                onClick={() => setActiveTab('mascotas')}
                className={navItemClass('mascotas', 'w-full text-left')}
              >
                <Dog size={20} /> Mascotas
              </button>

              <button
                onClick={() => setActiveTab('duenos')}
                className={navItemClass('duenos', 'w-full text-left')}
              >
                <Users size={20} /> Dueños
              </button>

              <button
                onClick={() => setActiveTab('facturas')}
                className={navItemClass('facturas', 'w-full text-left')}
              >
                <Receipt size={20} /> Facturación
              </button>
            </>
          )}

          {(isAdmin || isVet) && (
            <button
              onClick={() => setActiveTab('citas')}
              className={navItemClass('citas', 'w-full text-left')}
            >
              <Calendar size={20} /> Historial Médico
            </button>
          )}

          {isAdmin && (
            <>
              <button
                onClick={() => setActiveTab('reportes')}
                className={navItemClass('reportes', 'w-full text-left')}
              >
                <BarChart3 size={20} /> Reportes SQL
              </button>

              <div className="mt-8 mb-2 px-6 text-xs text-teal-200 font-bold uppercase tracking-wider">
                Módulo Admin
              </div>

              <button
                onClick={() => setActiveTab('auditoria')}
                className={navItemClass('auditoria', 'w-full text-left text-amber-200')}
              >
                <ShieldAlert size={20} /> Logs y Triggers
              </button>
            </>
          )}
        </nav>
      </aside>

      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="bg-white h-20 px-8 flex items-center justify-between shadow-sm z-0">
          <h2 className="text-2xl font-semibold text-slate-800">
            {activeTab === 'dashboard' && 'Panel de Control General'}
            {activeTab === 'duenos' && 'Directorio de Dueños'}
            {activeTab === 'mascotas' && 'Registro de Mascotas'}
            {activeTab === 'citas' && 'Historial de Consultas y Tratamientos'}
            {activeTab === 'reportes' && 'Reportes y Vistas Avanzadas'}
            {activeTab === 'facturas' && 'Control de Facturación'}
            {activeTab === 'auditoria' && 'Auditoría del Sistema (Triggers & Errores)'}
          </h2>

          <div className="flex items-center gap-6">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-full bg-slate-200 overflow-hidden shadow-inner">
                <img
                  src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${user.nombre_completo}`}
                  alt="Usuario"
                />
              </div>
              <div className="text-sm">
                <p className="font-bold text-slate-700 text-base">{user.nombre_completo}</p>
                <p className="text-slate-500">
                  {user.rol} {user.especialidad ? `• ${user.especialidad}` : ''}
                </p>
              </div>
            </div>

            <div className="h-8 w-px bg-slate-200 mx-2"></div>

            <button
              onClick={() => {
                setUser(null);
                setActiveTab('dashboard');
              }}
              className="flex items-center gap-2 text-slate-500 hover:text-red-500 transition-colors"
            >
              <LogOut size={20} /> Salir
            </button>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-8 relative">
          {activeTab === 'dashboard' && (
            <>
              <div className="grid grid-cols-3 gap-6 mb-8">
                <div className="bg-[#22c55e] rounded-xl p-6 text-white shadow-md flex items-center gap-4">
                  <Dog size={48} className="opacity-80" />
                  <div>
                    <p className="text-4xl font-bold">{stats.total_mascotas}</p>
                    <p className="text-emerald-100 font-medium">Mascotas en Sistema</p>
                  </div>
                </div>

                <div className="bg-[#3b82f6] rounded-xl p-6 text-white shadow-md flex items-center gap-4">
                  <Calendar size={48} className="opacity-80" />
                  <div>
                    <p className="text-4xl font-bold">{historial.length}</p>
                    <p className="text-blue-100 font-medium">Mis Expedientes</p>
                  </div>
                </div>

                <div className="bg-[#f97316] rounded-xl p-6 text-white shadow-md flex items-center gap-4">
                  <HeartPulse size={48} className="opacity-80" />
                  <div>
                    <p className="text-4xl font-bold">{stats.total_tratamientos}</p>
                    <p className="text-orange-100 font-medium">Tratamientos Globales</p>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-6">
                <div className="col-span-1 flex flex-col gap-6">
                  <div className="bg-white rounded-xl shadow-sm p-6">
                    <h3 className="font-bold text-lg text-slate-800 mb-4 pb-2 border-b">
                      Mis Consultas Recientes
                    </h3>

                    <ul className="space-y-4 text-sm">
                      {historial.length > 0 ? (
                        historial.slice(0, 4).map((cita) => {
                          const date = new Date(cita.fecha_consulta);
                          return (
                            <li
                              key={cita.consulta_id}
                              className="flex gap-3 border-b pb-2 last:border-0"
                            >
                              <span className="text-[#22c55e] font-semibold min-w-[50px]">
                                {date.toLocaleDateString('es-ES', {
                                  day: '2-digit',
                                  month: 'short',
                                })}
                              </span>
                              <div className="flex flex-col">
                                <span className="font-bold text-slate-700">
                                  {cita.mascota_nombre}
                                </span>
                                <span className="text-slate-500 text-xs">{cita.motivo}</span>
                              </div>
                            </li>
                          );
                        })
                      ) : (
                        <li className="text-slate-500 text-center py-2">
                          No tienes consultas registradas.
                        </li>
                      )}
                    </ul>
                  </div>
                </div>

                <div className="col-span-2 flex flex-col gap-6">
                  <div className="bg-white rounded-xl shadow-sm p-6">
                    <h3 className="font-bold text-lg text-slate-800 mb-4">
                      Información del Paciente Destacado
                    </h3>

                    {expedienteDestacado ? (
                      <div className="flex gap-6 border rounded-xl p-4 bg-slate-50/50">
                        <div className="w-40 h-40 bg-slate-200 rounded-lg overflow-hidden shrink-0">
                          <img
                            src={getPetImage(expedienteDestacado)}
                            alt={expedienteDestacado.mascota_nombre}
                            className="w-full h-full object-cover"
                            onError={(e) => {
                              e.currentTarget.src = fallbackPetImage;
                            }}
                          />
                        </div>

                        <div className="flex flex-col justify-center flex-1">
                          <h2 className="text-3xl font-bold text-slate-800 mb-3">
                            {expedienteDestacado.mascota_nombre}
                          </h2>

                          <div className="grid grid-cols-2 gap-4 text-sm mb-4">
                            <div>
                              <p className="text-slate-600">
                                <strong className="text-slate-800">Especie:</strong>{' '}
                                {expedienteDestacado.especie}
                              </p>
                              <p className="text-slate-600">
                                <strong className="text-slate-800">Raza:</strong>{' '}
                                {expedienteDestacado.raza}
                              </p>
                            </div>
                            <div>
                              <p className="text-slate-600">
                                <strong className="text-slate-800">Dueño:</strong>{' '}
                                {expedienteDestacado.dueno_nombre}
                              </p>
                              <p className="text-slate-600">
                                <strong className="text-slate-800">Tel:</strong>{' '}
                                {expedienteDestacado.dueno_telefono}
                              </p>
                            </div>
                          </div>

                          {expedienteDestacado.diagnostico && (
                            <div className="mt-2 bg-[#fff7ed] border border-orange-200 rounded-lg p-3">
                              <p className="font-bold text-orange-800 flex items-center gap-2 mb-1">
                                <Activity size={16} /> Expediente Clínico
                              </p>
                              <p className="text-sm text-slate-700">
                                <strong>Diagnóstico:</strong> {expedienteDestacado.diagnostico}
                              </p>
                              <p className="text-sm text-slate-700">
                                <strong>Tratamiento:</strong> {expedienteDestacado.tratamiento}
                              </p>
                              <p className="text-sm text-slate-700">
                                <strong>Observaciones:</strong>{' '}
                                {expedienteDestacado.observaciones || 'Sin observaciones'}
                              </p>
                            </div>
                          )}
                        </div>
                      </div>
                    ) : (
                      <p className="text-center text-slate-500 py-10">
                        Sin pacientes asignados.
                      </p>
                    )}
                  </div>
                </div>
              </div>
            </>
          )}

          {activeTab === 'duenos' && (isAdmin || isRecep) && (
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex justify-between items-center mb-6">
                <h3 className="font-bold text-xl text-slate-800">Directorio de Dueños</h3>
                <button
                  onClick={() => setShowDuenoModal(true)}
                  className="bg-brandTeal text-white px-4 py-2 rounded shadow hover:bg-teal-700 transition-colors"
                >
                  + Nuevo Dueño (Con Cifrado)
                </button>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="border-b-2 border-slate-200 text-slate-500">
                      <th className="p-3">ID</th>
                      <th className="p-3">Nombre</th>
                      <th className="p-3">Email</th>
                      <th className="p-3">Teléfono</th>
                      <th className="p-3">Dirección</th>
                      <th className="p-3">Doc (Oculto/Cifrado)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {duenos.map((dueno) => (
                      <tr key={dueno.dueno_id} className="border-b hover:bg-slate-50">
                        <td className="p-3 font-semibold text-slate-700">#{dueno.dueno_id}</td>
                        <td className="p-3 font-bold text-brandTeal">{dueno.nombre_completo}</td>
                        <td className="p-3 text-slate-600">{dueno.email}</td>
                        <td className="p-3 text-slate-600">{dueno.telefono}</td>
                        <td className="p-3 text-slate-500 text-sm">{dueno.direccion}</td>
                        <td className="p-3 text-xs text-slate-400 font-mono">
                          {hiddenEncryptedDoc(dueno.numero_documento)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'mascotas' && (isAdmin || isRecep) && (
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex justify-between items-center mb-6">
                <h3 className="font-bold text-xl text-slate-800">Registro de Mascotas</h3>
                <button
                  onClick={() => setShowPetModal(true)}
                  className="bg-[#3b82f6] text-white px-4 py-2 rounded shadow hover:bg-blue-700 transition-colors"
                >
                  + Nueva Mascota
                </button>
              </div>

              <div className="grid grid-cols-3 gap-6">
                {mascotas.map((mascota) => {
                  const dueno = duenos.find(
                    (d) => Number(d.dueno_id) === Number(mascota.dueno)
                  );

                  return (
                    <div
                      key={mascota.mascota_id}
                      className="border rounded-xl p-4 flex gap-4 items-center bg-slate-50"
                    >
                      <div className="w-16 h-16 rounded-full overflow-hidden shadow-sm bg-white border">
                        <img
                          src={getPetImage(mascota)}
                          alt={mascota.nombre}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            e.currentTarget.src = fallbackPetImage;
                          }}
                        />
                      </div>

                      <div>
                        <h4 className="font-bold text-lg text-slate-800">{mascota.nombre}</h4>
                        <p className="text-sm text-slate-500">
                          {mascota.especie} • {mascota.raza}
                        </p>
                        <p className="text-xs text-slate-400 mt-1">
                          Dueño: {dueno ? dueno.nombre_completo : '...'}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {activeTab === 'citas' && (isAdmin || isVet) && (
            <div className="bg-white rounded-xl shadow-sm p-6">
              <div className="flex justify-between items-center mb-6">
                <h3 className="font-bold text-xl text-slate-800">Historial Médico</h3>
                <button
                  onClick={() => setShowConsultaModal(true)}
                  className="bg-[#f97316] text-white px-4 py-2 rounded shadow hover:bg-orange-600 transition-colors flex items-center gap-2"
                >
                  <Stethoscope size={18} />
                  + Nueva Consulta Integral
                </button>
              </div>

              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b-2 border-slate-200 text-slate-500">
                    <th className="p-3">Fecha</th>
                    <th className="p-3">Paciente</th>
                    <th className="p-3">Motivo Consulta</th>
                    <th className="p-3">Diagnóstico (BD)</th>
                    <th className="p-3">Estado</th>
                  </tr>
                </thead>
                <tbody>
                  {historial.map((cita) => {
                    const date = new Date(cita.fecha_consulta);

                    return (
                      <tr key={cita.consulta_id} className="border-b hover:bg-slate-50">
                        <td className="p-3 text-slate-600">{date.toLocaleDateString()}</td>
                        <td className="p-3 font-bold text-brandTeal">
                          {cita.mascota_nombre}{' '}
                          <span className="text-xs text-slate-400 font-normal">
                            ({cita.dueno_nombre})
                          </span>
                        </td>
                        <td className="p-3 text-slate-600">{cita.motivo}</td>
                        <td className="p-3 text-slate-500 italic text-sm">
                          {cita.diagnostico || 'Sin diagnóstico registrado'}
                        </td>
                        <td className="p-3">
                          <span
                            className={`px-2 py-1 rounded text-xs font-bold ${
                              cita.estado === 'Atendida'
                                ? 'bg-emerald-100 text-emerald-700'
                                : 'bg-amber-100 text-amber-700'
                            }`}
                          >
                            {cita.estado}
                          </span>
                        </td>
                      </tr>
                    );
                  })}

                  {historial.length === 0 && (
                    <tr>
                      <td colSpan="5" className="p-4 text-center text-slate-500">
                        No hay consultas registradas todavía.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}

          {activeTab === 'facturas' && (isAdmin || isRecep) && (
            <div className="bg-white rounded-xl shadow-sm p-6">
              <h3 className="font-bold text-xl text-slate-800 mb-4">Historial de Facturación</h3>

              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b-2 border-slate-200 text-slate-500 bg-slate-50">
                    <th className="p-3">ID Factura</th>
                    <th className="p-3">Folio</th>
                    <th className="p-3">Fecha</th>
                    <th className="p-3">Motivo Consulta</th>
                    <th className="p-3">Método de Pago</th>
                    <th className="p-3">Total</th>
                  </tr>
                </thead>
                <tbody>
                  {datosAdmin.facturas.map((fac, idx) => (
                    <tr key={idx} className="border-b hover:bg-slate-50">
                      <td className="p-3 font-semibold text-slate-700">#{fac.factura_id}</td>
                      <td className="p-3 text-slate-600">{fac.folio || 'N/A'}</td>
                      <td className="p-3 text-slate-600">{fac.fecha}</td>
                      <td className="p-3 text-slate-600 italic">{fac.motivo}</td>
                      <td className="p-3">
                        <span className="bg-blue-100 text-blue-700 px-2 py-1 rounded text-xs font-bold">
                          {fac.metodo_pago}
                        </span>
                      </td>
                      <td className="p-3 font-bold text-emerald-600">${fac.total}</td>
                    </tr>
                  ))}

                  {datosAdmin.facturas.length === 0 && (
                    <tr>
                      <td colSpan="6" className="p-4 text-center text-slate-500">
                        No hay facturas registradas.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}

          {activeTab === 'reportes' && isAdmin && (
            <div className="grid grid-cols-2 gap-6">
              <div className="col-span-2 bg-white rounded-xl shadow-sm p-6 border-l-4 border-purple-500">
                <h3 className="font-bold text-lg text-slate-800 mb-2">
                  Vista PIVOT Dinámica (Consultas por Mes)
                </h3>
                <p className="text-sm text-slate-500 mb-4">
                  Generada directamente desde SQL Server usando <code>PIVOT</code>.
                </p>

                <div className="overflow-x-auto">
                  <table className="w-full text-sm text-center border">
                    <thead className="bg-slate-100 font-bold text-slate-600">
                      <tr>
                        <th className="p-2 border text-left">Veterinario</th>
                        <th className="p-2 border">Ene</th>
                        <th className="p-2 border">Feb</th>
                        <th className="p-2 border">Mar</th>
                        <th className="p-2 border">Abr</th>
                        <th className="p-2 border">May</th>
                        <th className="p-2 border">Jun</th>
                      </tr>
                    </thead>
                    <tbody>
                      {datosAdmin.pivot.map((p, i) => (
                        <tr key={i}>
                          <td className="p-2 border text-left font-semibold">{p.veterinario}</td>
                          <td className="p-2 border">{p.January || 0}</td>
                          <td className="p-2 border">{p.February || 0}</td>
                          <td className="p-2 border">{p.March || 0}</td>
                          <td className="p-2 border">{p.April || 0}</td>
                          <td className="p-2 border">{p.May || 0}</td>
                          <td className="p-2 border">{p.June || 0}</td>
                        </tr>
                      ))}

                      {datosAdmin.pivot.length === 0 && (
                        <tr>
                          <td colSpan="7" className="p-4 text-center text-slate-500">
                            No hay datos para el reporte PIVOT.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>

              <div className="bg-white rounded-xl shadow-sm p-6">
                <h3 className="font-bold text-lg text-slate-800 mb-4 flex items-center gap-2">
                  <Trophy className="text-amber-500" />
                  Ranking de Veterinarios
                </h3>

                <div className="space-y-4">
                  {reportes.ranking.map((vet, idx) => (
                    <div key={idx} className="flex items-center justify-between border-b pb-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-amber-100 text-amber-700 font-bold flex items-center justify-center">
                          {vet.ranking}
                        </div>
                        <div>
                          <p className="font-bold text-slate-700">{vet.veterinario}</p>
                          <p className="text-xs text-slate-500">{vet.especialidad}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-xl font-bold text-brandTeal">{vet.total_consultas}</p>
                        <p className="text-xs text-slate-500">Consultas</p>
                      </div>
                    </div>
                  ))}

                  {reportes.ranking.length === 0 && (
                    <p className="text-slate-500 text-sm">No hay datos de ranking todavía.</p>
                  )}
                </div>
              </div>

              <div className="bg-white rounded-xl shadow-sm p-6">
                <h3 className="font-bold text-lg text-slate-800 mb-4 flex items-center gap-2">
                  <Star className="text-blue-500" />
                  Clasificación de Clientes (CASE)
                </h3>

                <div className="space-y-4">
                  {reportes.clientes.map((cliente, idx) => (
                    <div key={idx} className="flex items-center justify-between border-b pb-3">
                      <div>
                        <p className="font-bold text-slate-700">{cliente.dueno}</p>
                        <p className="text-xs text-slate-500">
                          Histórico: {cliente.total_consultas} citas
                        </p>
                      </div>
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-bold ${
                          cliente.categoria === 'Cliente VIP'
                            ? 'bg-purple-100 text-purple-700'
                            : cliente.categoria === 'Cliente Frecuente'
                            ? 'bg-blue-100 text-blue-700'
                            : 'bg-slate-100 text-slate-600'
                        }`}
                      >
                        {cliente.categoria}
                      </span>
                    </div>
                  ))}

                  {reportes.clientes.length === 0 && (
                    <p className="text-slate-500 text-sm">No hay clientes clasificados todavía.</p>
                  )}
                </div>
              </div>
            </div>
          )}

          {activeTab === 'auditoria' && isAdmin && (
            <div className="space-y-6">
              <div className="bg-red-50 border border-red-200 rounded-xl p-6">
                <h3 className="font-bold text-xl text-red-800 mb-2 flex items-center gap-2">
                  <ShieldAlert /> Registro de Errores (TRY/CATCH)
                </h3>
                <p className="text-sm text-red-600 mb-4">
                  Atrapados por el <code>BEGIN CATCH</code> en la base de datos.
                </p>

                <table className="w-full text-left text-sm border bg-white">
                  <thead className="bg-red-100 text-red-800">
                    <tr>
                      <th className="p-2">Fecha</th>
                      <th className="p-2">Procedimiento</th>
                      <th className="p-2">Mensaje de Error</th>
                    </tr>
                  </thead>
                  <tbody>
                    {datosAdmin.errores.map((err, i) => (
                      <tr key={i} className="border-b">
                        <td className="p-2 text-slate-500">
                          {new Date(err.fecha_error).toLocaleString()}
                        </td>
                        <td className="p-2 font-mono text-red-600">{err.procedimiento}</td>
                        <td className="p-2">{err.mensaje_error}</td>
                      </tr>
                    ))}
                    {datosAdmin.errores.length === 0 && (
                      <tr>
                        <td colSpan="3" className="p-4 text-center text-slate-500">
                          No hay errores registrados. El sistema es estable.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              <div className="bg-amber-50 border border-amber-200 rounded-xl p-6">
                <h3 className="font-bold text-xl text-amber-800 mb-2 flex items-center gap-2">
                  <Activity /> Auditoría de Consultas
                </h3>

                <table className="w-full text-left text-sm border bg-white">
                  <thead className="bg-amber-100 text-amber-800">
                    <tr>
                      <th className="p-2">ID Consulta</th>
                      <th className="p-2">Acción</th>
                      <th className="p-2">Cambio de Estado</th>
                      <th className="p-2">Usuario BD</th>
                    </tr>
                  </thead>
                  <tbody>
                    {datosAdmin.auditoria_consultas.map((aud, i) => (
                      <tr key={i} className="border-b">
                        <td className="p-2 font-bold">#{aud.consulta_id}</td>
                        <td className="p-2">
                          <span className="bg-amber-100 text-amber-800 px-2 py-1 rounded font-bold text-xs">
                            {aud.accion}
                          </span>
                        </td>
                        <td className="p-2">
                          {aud.estado_anterior || 'N/A'} ➡️{' '}
                          <span className="text-emerald-600 font-bold">
                            {aud.estado_nuevo || 'N/A'}
                          </span>
                        </td>
                        <td className="p-2 font-mono text-xs">{aud.usuario_bd}</td>
                      </tr>
                    ))}
                    {datosAdmin.auditoria_consultas.length === 0 && (
                      <tr>
                        <td colSpan="4" className="p-4 text-center text-slate-500">
                          No hay auditorías de consultas registradas aún.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              <div className="bg-blue-50 border border-blue-200 rounded-xl p-6">
                <h3 className="font-bold text-xl text-blue-800 mb-2 flex items-center gap-2">
                  <Activity /> Auditoría de Tratamientos
                </h3>

                <table className="w-full text-left text-sm border bg-white">
                  <thead className="bg-blue-100 text-blue-800">
                    <tr>
                      <th className="p-2">ID Tratamiento</th>
                      <th className="p-2">ID Consulta</th>
                      <th className="p-2">Acción</th>
                      <th className="p-2">Usuario BD</th>
                    </tr>
                  </thead>
                  <tbody>
                    {datosAdmin.auditoria_tratamientos.map((aud, i) => (
                      <tr key={i} className="border-b">
                        <td className="p-2 font-bold">#{aud.tratamiento_id}</td>
                        <td className="p-2">#{aud.consulta_id}</td>
                        <td className="p-2">
                          <span className="bg-blue-100 text-blue-800 px-2 py-1 rounded font-bold text-xs">
                            {aud.accion}
                          </span>
                        </td>
                        <td className="p-2 font-mono text-xs">{aud.usuario_bd}</td>
                      </tr>
                    ))}
                    {datosAdmin.auditoria_tratamientos.length === 0 && (
                      <tr>
                        <td colSpan="4" className="p-4 text-center text-slate-500">
                          No hay auditorías de tratamientos registradas aún.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-6">
                <h3 className="font-bold text-xl text-emerald-800 mb-2 flex items-center gap-2">
                  <Receipt /> Auditoría de Facturas
                </h3>

                <table className="w-full text-left text-sm border bg-white">
                  <thead className="bg-emerald-100 text-emerald-800">
                    <tr>
                      <th className="p-2">ID Factura</th>
                      <th className="p-2">ID Consulta</th>
                      <th className="p-2">Acción</th>
                      <th className="p-2">Total</th>
                      <th className="p-2">Usuario BD</th>
                    </tr>
                  </thead>
                  <tbody>
                    {datosAdmin.auditoria_facturas.map((aud, i) => (
                      <tr key={i} className="border-b">
                        <td className="p-2 font-bold">#{aud.factura_id}</td>
                        <td className="p-2">#{aud.consulta_id}</td>
                        <td className="p-2">
                          <span className="bg-emerald-100 text-emerald-800 px-2 py-1 rounded font-bold text-xs">
                            {aud.accion}
                          </span>
                        </td>
                        <td className="p-2">{aud.total_registrado ?? aud.total_nuevo ?? 'N/A'}</td>
                        <td className="p-2 font-mono text-xs">{aud.usuario_bd}</td>
                      </tr>
                    ))}
                    {datosAdmin.auditoria_facturas.length === 0 && (
                      <tr>
                        <td colSpan="5" className="p-4 text-center text-slate-500">
                          No hay auditorías de facturas registradas aún.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {showPetModal && (isAdmin || isRecep) && (
            <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
              <div className="bg-white rounded-xl shadow-2xl p-6 w-[400px]">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-xl font-bold text-slate-800">
                    Registrar Nueva Mascota
                  </h3>
                  <button
                    onClick={() => setShowPetModal(false)}
                    className="text-slate-400 hover:text-red-500"
                  >
                    <X size={20} />
                  </button>
                </div>

                <form onSubmit={handleAddPet} className="space-y-3 text-sm">
                  <div>
                    <label className="block font-medium text-slate-700 mb-1">Nombre</label>
                    <input
                      type="text"
                      required
                      value={newPet.nombre}
                      onChange={(e) =>
                        setNewPet({ ...newPet, nombre: e.target.value })
                      }
                      className="w-full border rounded p-2 focus:ring focus:ring-teal-200 outline-none"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block font-medium text-slate-700 mb-1">Especie</label>
                      <input
                        type="text"
                        placeholder="Perro, Gato..."
                        required
                        value={newPet.especie}
                        onChange={(e) =>
                          setNewPet({ ...newPet, especie: e.target.value })
                        }
                        className="w-full border rounded p-2 focus:ring focus:ring-teal-200 outline-none"
                      />
                    </div>

                    <div>
                      <label className="block font-medium text-slate-700 mb-1">Raza</label>
                      <input
                        type="text"
                        required
                        value={newPet.raza}
                        onChange={(e) =>
                          setNewPet({ ...newPet, raza: e.target.value })
                        }
                        className="w-full border rounded p-2 focus:ring focus:ring-teal-200 outline-none"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block font-medium text-slate-700 mb-1">Edad</label>
                      <input
                        type="number"
                        required
                        value={newPet.edad}
                        onChange={(e) =>
                          setNewPet({ ...newPet, edad: e.target.value })
                        }
                        className="w-full border rounded p-2 focus:ring focus:ring-teal-200 outline-none"
                      />
                    </div>

                    <div>
                      <label className="block font-medium text-slate-700 mb-1">
                        Peso (kg)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        required
                        value={newPet.peso}
                        onChange={(e) =>
                          setNewPet({ ...newPet, peso: e.target.value })
                        }
                        className="w-full border rounded p-2 focus:ring focus:ring-teal-200 outline-none"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block font-medium text-slate-700 mb-1">
                      Dueño (Selecciona uno)
                    </label>
                    <select
                      required
                      value={newPet.dueno_id}
                      onChange={(e) =>
                        setNewPet({ ...newPet, dueno_id: e.target.value })
                      }
                      className="w-full border rounded p-2 bg-white focus:ring focus:ring-teal-200 outline-none"
                    >
                      <option value="">-- Elegir Dueño --</option>
                      {duenos.map((d) => (
                        <option key={d.dueno_id} value={d.dueno_id}>
                          {d.nombre_completo}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div className="flex gap-3 mt-6 pt-4 border-t">
                    <button
                      type="button"
                      onClick={() => setShowPetModal(false)}
                      className="flex-1 bg-slate-200 text-slate-700 py-2 rounded font-bold hover:bg-slate-300 transition-colors"
                    >
                      Cancelar
                    </button>
                    <button
                      type="submit"
                      className="flex-1 bg-[#3b82f6] text-white py-2 rounded font-bold hover:bg-blue-700 transition-colors"
                    >
                      Guardar
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}

          {showDuenoModal && (isAdmin || isRecep) && (
            <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
              <div className="bg-white rounded-xl shadow-2xl p-6 w-[400px]">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-xl font-bold text-brandTeal flex items-center gap-2">
                    <ShieldAlert size={20} /> Registro Seguro
                  </h3>
                  <button onClick={() => setShowDuenoModal(false)}>
                    <X size={20} />
                  </button>
                </div>

                <p className="text-xs text-slate-500 mb-4">
                  Los datos sensibles serán cifrados en la base de datos usando el
                  procedimiento almacenado con llave AES_256.
                </p>

                <form onSubmit={handleAddDueno} className="space-y-3 text-sm">
                  <input
                    type="text"
                    placeholder="Nombre Completo"
                    required
                    value={newDueno.nombre_completo}
                    onChange={(e) =>
                      setNewDueno({ ...newDueno, nombre_completo: e.target.value })
                    }
                    className="w-full border rounded p-2"
                  />

                  <input
                    type="email"
                    placeholder="Correo Electrónico"
                    required
                    value={newDueno.email}
                    onChange={(e) =>
                      setNewDueno({ ...newDueno, email: e.target.value })
                    }
                    className="w-full border rounded p-2"
                  />

                  <input
                    type="text"
                    placeholder="Teléfono"
                    required
                    value={newDueno.telefono}
                    onChange={(e) =>
                      setNewDueno({ ...newDueno, telefono: e.target.value })
                    }
                    className="w-full border rounded p-2"
                  />

                  <input
                    type="text"
                    placeholder="Dirección"
                    required
                    value={newDueno.direccion}
                    onChange={(e) =>
                      setNewDueno({ ...newDueno, direccion: e.target.value })
                    }
                    className="w-full border rounded p-2"
                  />

                  <div className="grid grid-cols-2 gap-3">
                    <select
                      required
                      value={newDueno.tipo_documento}
                      onChange={(e) =>
                        setNewDueno({ ...newDueno, tipo_documento: e.target.value })
                      }
                      className="border rounded p-2"
                    >
                      <option value="INE">INE</option>
                      <option value="Pasaporte">Pasaporte</option>
                    </select>

                    <input
                      type="text"
                      placeholder="No. Documento"
                      required
                      value={newDueno.numero_documento}
                      onChange={(e) =>
                        setNewDueno({
                          ...newDueno,
                          numero_documento: e.target.value,
                        })
                      }
                      className="border rounded p-2 border-red-300 bg-red-50"
                    />
                  </div>

                  <button
                    type="submit"
                    className="w-full bg-brandTeal text-white py-2 rounded font-bold mt-4"
                  >
                    Guardar y Cifrar
                  </button>
                </form>
              </div>
            </div>
          )}

          {showConsultaModal && (isAdmin || isVet) && (
            <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
              <div className="bg-white rounded-xl shadow-2xl p-6 w-[520px] max-h-[90vh] overflow-y-auto">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="text-xl font-bold text-orange-600 flex items-center gap-2">
                    <Stethoscope size={20} />
                    Nueva Consulta Integral
                  </h3>
                  <button onClick={() => setShowConsultaModal(false)}>
                    <X size={20} />
                  </button>
                </div>

                <p className="text-xs text-slate-500 mb-4">
                  Ejecuta una transacción completa: consulta, tratamiento cifrado,
                  factura, secuencia de folio y triggers de auditoría.
                </p>

                <form onSubmit={handleAddConsulta} className="space-y-3 text-sm">
                  <div>
                    <label className="block font-medium text-slate-700 mb-1">
                      Paciente
                    </label>
                    <select
                      required
                      value={newConsulta.mascota_id}
                      onChange={(e) =>
                        setNewConsulta({ ...newConsulta, mascota_id: e.target.value })
                      }
                      className="w-full border rounded p-2"
                    >
                      <option value="">-- Seleccionar Paciente --</option>
                      {mascotas.map((m) => (
                        <option key={m.mascota_id} value={m.mascota_id}>
                          {m.nombre} ({m.especie})
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block font-medium text-slate-700 mb-1">
                      Motivo de la consulta
                    </label>
                    <input
                      type="text"
                      placeholder="Ej. Chequeo general, vacuna, infección..."
                      required
                      value={newConsulta.motivo}
                      onChange={(e) =>
                        setNewConsulta({ ...newConsulta, motivo: e.target.value })
                      }
                      className="w-full border rounded p-2"
                    />
                  </div>

                  <div className="p-3 bg-red-50 border border-red-200 rounded space-y-2">
                    <p className="text-xs font-bold text-red-800">
                      Datos clínicos cifrados con AES_256
                    </p>

                    <textarea
                      placeholder="Diagnóstico"
                      required
                      value={newConsulta.diagnostico}
                      onChange={(e) =>
                        setNewConsulta({ ...newConsulta, diagnostico: e.target.value })
                      }
                      className="w-full border rounded p-2 h-20 resize-none"
                    />

                    <textarea
                      placeholder="Tratamiento recetado"
                      required
                      value={newConsulta.tratamiento}
                      onChange={(e) =>
                        setNewConsulta({ ...newConsulta, tratamiento: e.target.value })
                      }
                      className="w-full border rounded p-2 h-20 resize-none"
                    />

                    <textarea
                      placeholder="Observaciones (opcional)"
                      value={newConsulta.observaciones}
                      onChange={(e) =>
                        setNewConsulta({ ...newConsulta, observaciones: e.target.value })
                      }
                      className="w-full border rounded p-2 h-20 resize-none"
                    />
                  </div>

                  <div className="grid grid-cols-3 gap-2">
                    <div>
                      <label className="block font-medium text-slate-700 mb-1">
                        Total
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        placeholder="Total $"
                        required
                        value={newConsulta.total}
                        onChange={(e) =>
                          setNewConsulta({ ...newConsulta, total: e.target.value })
                        }
                        className="w-full border rounded p-2"
                      />
                    </div>

                    <div>
                      <label className="block font-medium text-slate-700 mb-1">
                        Método
                      </label>
                      <select
                        value={newConsulta.metodo_pago}
                        onChange={(e) =>
                          setNewConsulta({
                            ...newConsulta,
                            metodo_pago: e.target.value,
                          })
                        }
                        className="w-full border rounded p-2"
                      >
                        <option value="Tarjeta">Tarjeta</option>
                        <option value="Efectivo">Efectivo</option>
                        <option value="Transferencia">Transferencia</option>
                      </select>
                    </div>

                    <div>
                      <label className="block font-medium text-slate-700 mb-1">
                        Referencia
                      </label>
                      <input
                        type="text"
                        placeholder="N/A o folio"
                        required
                        value={newConsulta.referencia}
                        onChange={(e) =>
                          setNewConsulta({
                            ...newConsulta,
                            referencia: e.target.value,
                          })
                        }
                        className="w-full border rounded p-2 bg-red-50"
                      />
                    </div>
                  </div>

                  <div className="flex gap-3 mt-6 pt-4 border-t">
                    <button
                      type="button"
                      onClick={() => setShowConsultaModal(false)}
                      className="flex-1 bg-slate-200 text-slate-700 py-2 rounded font-bold hover:bg-slate-300 transition-colors"
                    >
                      Cancelar
                    </button>
                    <button
                      type="submit"
                      className="flex-1 bg-orange-500 text-white py-2 rounded font-bold hover:bg-orange-600 transition-colors"
                    >
                      Ejecutar Transacción Completa
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}

export default App;