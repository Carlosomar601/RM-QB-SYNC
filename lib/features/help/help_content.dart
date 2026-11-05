/// All help text, bundled offline (Spanish).
library;

abstract final class Routes {
  static const login = '/login';
  static const cambiarContrasena = '/cambiar-contrasena';
  static const asistente = '/asistente';
  static const dashboard = '/inicio';
  static const sincronizaciones = '/sincronizaciones';
  static const reportes = '/reportes';
  static const vistaPrevia = '/vista-previa';
  static const mapeo = '/mapeo';
  static const configuracion = '/configuracion';
  static const historial = '/historial';
  static const auditoria = '/auditoria';
  static const usuarios = '/usuarios';
  static const ayuda = '/ayuda';
}

/// Single terminology table shared by UI labels and help text.
abstract final class Terms {
  static const asiento = 'asiento de diario';
  static const debe = 'Debe';
  static const haber = 'Haber';
  static const vistaPrevia = 'Vista Previa';
  static const mapeo = 'Mapeo de Cuentas';
  static const sincronizar = 'Sincronizar';
  static const configuracion = 'Configuración';
  static const apiPos = 'Acceso a la API del POS';
}

class HelpSection {
  const HelpSection(this.heading, this.paragraphs);
  final String heading;
  final List<String> paragraphs;
}

class HelpLink {
  const HelpLink(this.label, this.route);
  final String label;
  final String route;
}

class HelpArticle {
  const HelpArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.sections = const [],
    this.steps = const [],
    this.links = const [],
  });

  final String id;
  final String title;
  final String summary;
  final List<HelpSection> sections;

  /// Numbered steps (tutorials).
  final List<String> steps;
  final List<HelpLink> links;
}

class GlossaryEntry {
  const GlossaryEntry(this.term, this.definition);
  final String term;
  final String definition;
}

class FaqEntry {
  const FaqEntry({required this.question, required this.answer, this.fix, this.link});
  final String question;
  final String answer;
  final String? fix;
  final HelpLink? link;
}

abstract final class HelpContent {
  // -------------------------------------------------------------------------
  // Contextual articles (one per screen)
  // -------------------------------------------------------------------------
  static const Map<String, HelpArticle> screens = {
    Routes.login: HelpArticle(
      id: 'login',
      title: 'Iniciar sesión',
      summary: 'Entre con su usuario y contraseña de RM Ledger Sync (no son los de QuickBooks).',
      sections: [
        HelpSection('Primer uso', [
          'La primera vez se crea el usuario "admin" con una contraseña temporal. Se muestra en pantalla y '
              'también queda en C:\\ProgramData\\RMQBsync\\primer-acceso.txt. Al entrar se le pedirá cambiarla.',
        ]),
        HelpSection('Bloqueo', [
          'Después de 5 intentos fallidos la cuenta se bloquea 15 minutos. Un administrador puede desbloquearla '
              'desactivando y activando el usuario o restableciendo la contraseña.',
        ]),
        HelpSection('Recordarme', ['Si marca "Recordarme", la sesión se mantiene 30 días en este equipo.']),
      ],
    ),
    Routes.cambiarContrasena: HelpArticle(
      id: 'password',
      title: 'Cambiar contraseña',
      summary: 'Use al menos 8 caracteres con letras y números. Evite contraseñas usadas en otros sistemas.',
    ),
    Routes.asistente: HelpArticle(
      id: 'wizard',
      title: 'Asistente de configuración',
      summary: 'Le guía para dejar RM Ledger Sync listo: POS, QuickBooks, cuentas y programación.',
      sections: [
        HelpSection('Qué necesita', [
          'La dirección IP y el puerto del servidor del POS Retail Manager (ej.: 192.168.100.175 y 8180).',
          'El Client ID y Client Secret de su aplicación en developer.intuit.com (o los que trajo el instalador).',
          'Un usuario de QuickBooks Online con permiso de administrador para autorizar la conexión.',
        ]),
        HelpSection('Puede pausar', [
          'Lo que escriba se guarda como borrador. Puede salir y volver desde Ayuda → "Abrir asistente".',
        ]),
      ],
    ),
    Routes.dashboard: HelpArticle(
      id: 'dashboard',
      title: 'Inicio',
      summary: 'Resumen del estado: conexión con QuickBooks, POS, última sincronización y pendientes de configuración.',
      sections: [
        HelpSection('Lista de verificación', [
          'Cada punto en rojo tiene un botón "Ir" que le lleva exactamente a donde debe resolverlo.',
          'El recuadro "Siguiente paso recomendado" muestra una sola acción: la más importante ahora.',
        ]),
      ],
      links: [HelpLink('Ver Vista Previa', Routes.vistaPrevia), HelpLink('Ver Historial', Routes.historial)],
    ),
    Routes.sincronizaciones: HelpArticle(
      id: 'sync',
      title: 'Sincronizaciones',
      summary: 'Envíe ahora un rango a QuickBooks o programe envíos automáticos.',
      sections: [
        HelpSection('Sincronizar ahora', [
          'Envía un asiento de diario con los totales del rango elegido. Si ya existe un envío exitoso que '
              'cubra alguna de esas fechas, se omite para evitar duplicados.',
        ]),
        HelpSection('Programación', [
          'Diaria: envía el día actual a la hora indicada.',
          'Semanal: envía los últimos 7 días (hoy y los 6 anteriores) el día de la semana indicado.',
          'Mensual: envía el mes anterior completo; el día elegido solo indica cuándo se ejecuta.',
          'La aplicación debe estar abierta (puede estar minimizada en la bandeja). Si el equipo estaba apagado, '
              'el envío pendiente se ejecuta al volver a abrir la aplicación.',
        ]),
      ],
      links: [HelpLink('Revisar antes en Vista Previa', Routes.vistaPrevia)],
    ),
    Routes.reportes: HelpArticle(
      id: 'reports',
      title: 'Reportes',
      summary: 'Sección reservada para reportes futuros. Mientras tanto use Historial y Vista Previa.',
      sections: [
        HelpSection('Mientras tanto', [
          'Totales por categoría de cualquier rango: Vista Previa → paso 2 "Revisar".',
          'Qué se envió a QuickBooks y con qué resultado: Historial.',
          'Diferencias entre ventas y pagos por día: Vista Previa → "Diagnosticar diferencia".',
        ]),
      ],
      links: [HelpLink('Vista Previa', Routes.vistaPrevia), HelpLink('Historial', Routes.historial)],
    ),
    Routes.vistaPrevia: HelpArticle(
      id: 'preview',
      title: 'Vista Previa',
      summary: 'Revise exactamente qué asiento se enviará a QuickBooks antes de enviarlo.',
      sections: [
        HelpSection('Pasos', [
          '1) Elija el rango de fechas. 2) Revise el resumen por categoría y el asiento (Debe/Haber). '
              '3) Confirme y envíe.',
        ]),
        HelpSection('Si no cuadra', [
          'Use "Diagnosticar diferencia": calcula Ventas − Pagos por día y le muestra los días con diferencia. '
              'Las causas típicas son descuentos (no forman parte del asiento) y cobros de facturas de días anteriores.',
          '"Ver detalle" muestra los datos crudos del POS de un día: filas de ventas, facturas y cobros cruzados.',
        ]),
        HelpSection('Descuentos', [
          'El total de descuentos se muestra solo como información; no se incluye en el asiento.',
        ]),
      ],
      links: [HelpLink('Configurar cuentas', Routes.mapeo)],
    ),
    Routes.mapeo: HelpArticle(
      id: 'mapping',
      title: 'Mapeo de Cuentas',
      summary: 'Indique a qué cuenta de QuickBooks va cada categoría del POS y si va al Debe o al Haber.',
      sections: [
        HelpSection('Recomendación', [
          'Categorías de Ventas (venta neta, IVU, cobros a facturas) normalmente van al Haber.',
          'Categorías de Pagos (efectivo, tarjetas, ATH Móvil, cheques, ventas a crédito) normalmente van al Debe.',
          'Si la cuenta es de Cuentas por Cobrar, QuickBooks exige un Cliente: elija tipo "Cliente" y el cliente genérico.',
        ]),
        HelpSection('Categorías nuevas', [
          'Se muestran todas las categorías conocidas y las que tuvieron movimiento en los últimos 30 días.',
        ]),
      ],
    ),
    Routes.configuracion: HelpArticle(
      id: 'settings',
      title: 'Configuración',
      summary: 'Conexión con QuickBooks, credenciales de Intuit y acceso a la API del POS.',
      sections: [
        HelpSection('Acceso a la API del POS', [
          'Escriba la IP (o nombre del equipo) y el puerto del servidor del POS. Presione "Probar conexión" antes '
              'de guardar. Al guardar, el cambio se aplica de inmediato sin reiniciar.',
          'Si la dirección no es de la red local (por ejemplo 8.8.8.8), se muestra una advertencia.',
          'Las últimas 5 direcciones quedan como accesos rápidos.',
        ]),
        HelpSection('QuickBooks', [
          '"Conectar con QuickBooks" abre el navegador para que autorice. Al terminar, vuelva a la aplicación.',
          'La autorización se renueva sola. Si pasan más de 100 días sin abrir la aplicación, deberá conectar de nuevo.',
        ]),
        HelpSection('Credenciales', [
          'Si deja el Client Secret en blanco al guardar, se conserva el que ya estaba guardado.',
        ]),
      ],
    ),
    Routes.historial: HelpArticle(
      id: 'history',
      title: 'Historial',
      summary: 'Las últimas 200 sincronizaciones con su resultado. Toque una fila para ver el detalle y el JSON enviado.',
      sections: [
        HelpSection('Estados', [
          'Exitosa: el asiento se creó en QuickBooks (verá su número).',
          'Fallida: no se creó nada; lea el mensaje para saber cómo resolverlo.',
          'Omitida: ya existía un envío exitoso para esas fechas.',
          'En curso: el envío se está procesando.',
        ]),
        HelpSection('Si una falló', [
          'Use "Ver error": explica qué pasó y ofrece la acción para resolverlo.',
          'Antes de cada envío se verifica si el rango ya fue aceptado por QuickBooks, así que volver a enviar no duplica.',
          'Use el buscador y los filtros para encontrar una fecha, un usuario o un estado.',
        ]),
      ],
    ),
    Routes.auditoria: HelpArticle(
      id: 'audit',
      title: 'Auditoría',
      summary: 'Registro de las últimas 300 acciones: inicios de sesión, cambios de configuración y envíos.',
      sections: [
        HelpSection('Cómo leerla', [
          'Cada fila indica la acción, quién la hizo, cuándo y el detalle.',
          'El icono indica el resultado: verde exitosa, ámbar omitida, rojo fallida.',
          'Las contraseñas, secretos y claves nunca se guardan ni se muestran aquí.',
        ]),
      ],
    ),
    Routes.usuarios: HelpArticle(
      id: 'users',
      title: 'Usuarios',
      summary: 'Cree usuarios, actívelos o desactívelos y restablezca contraseñas (solo administradores).',
      sections: [
        HelpSection('Reglas', [
          'Siempre debe quedar al menos un administrador activo.',
          'Los usuarios nuevos y las contraseñas restablecidas deben cambiarse en el primer inicio de sesión.',
        ]),
      ],
    ),
    Routes.ayuda: HelpArticle(
      id: 'help',
      title: 'Centro de Ayuda',
      summary: 'Referencia rápida, tutoriales y preguntas frecuentes. Presione F1 en cualquier pantalla.',
    ),
  };

  static HelpArticle forRoute(String location) {
    final key = screens.keys.firstWhere((k) => location.startsWith(k), orElse: () => Routes.ayuda);
    return screens[key]!;
  }

  // -------------------------------------------------------------------------
  // Quick reference
  // -------------------------------------------------------------------------
  static const features = <GlossaryEntry>[
    GlossaryEntry('Inicio', 'Estado general y lista de lo que falta configurar.'),
    GlossaryEntry('Sincronizaciones', 'Enviar ahora o programar envíos automáticos.'),
    GlossaryEntry('Vista Previa', 'Ver el asiento antes de enviarlo; diagnosticar diferencias.'),
    GlossaryEntry('Mapeo de Cuentas', 'Relacionar cada categoría del POS con una cuenta de QuickBooks.'),
    GlossaryEntry('Configuración', 'QuickBooks, credenciales de Intuit y dirección del POS.'),
    GlossaryEntry('Historial', 'Resultado de cada envío.'),
    GlossaryEntry('Auditoría', 'Quién hizo qué y cuándo.'),
    GlossaryEntry('Usuarios', 'Administrar accesos (solo administradores).'),
  ];

  static const glossary = <GlossaryEntry>[
    GlossaryEntry('Asiento de diario', 'Registro contable con líneas al Debe y al Haber que deben sumar lo mismo. RM Ledger Sync crea uno por rango de fechas.'),
    GlossaryEntry('Debe / Haber', 'Lados del asiento. Debe = débito (por ejemplo, dinero que entra a caja). Haber = crédito (por ejemplo, ingreso por ventas).'),
    GlossaryEntry('Balanceado', 'El total del Debe es igual al total del Haber (tolerancia de medio centavo).'),
    GlossaryEntry('Categoría del POS', 'Cada total que se lee del POS: Venta neta, IVU municipal, IVU estatal, Efectivo, Tarjetas, ATH Móvil, etc.'),
    GlossaryEntry('Mapeo', 'La regla que dice a qué cuenta de QuickBooks y a qué lado va cada categoría.'),
    GlossaryEntry('Cobros a facturas pendientes', 'Pagos recibidos en el rango para facturas a crédito (se buscan facturas de hasta 90 días atrás).'),
    GlossaryEntry('Pendiente de cobro', 'Ventas a crédito facturadas en el rango que aún no se han cobrado.'),
    GlossaryEntry('Cobros cruzados', 'Pagos recibidos un día por facturas de días anteriores; explican diferencias diarias.'),
    GlossaryEntry('Realm / Compañía', 'Identificador de su compañía en QuickBooks Online.'),
    GlossaryEntry('Sandbox / Producción', 'Sandbox es la compañía de pruebas de Intuit; Producción es su contabilidad real.'),
    GlossaryEntry('Duplicado', 'Un envío cuyo rango se cruza con otro envío exitoso. Se omite salvo que elija "Sincronizar de todas formas".'),
  ];

  static const buttons = <GlossaryEntry>[
    GlossaryEntry('ⓘ', 'Toque o pase el ratón para ver una explicación del control.'),
    GlossaryEntry('? (barra superior)', 'Abre la ayuda de la pantalla actual sin perder lo que estaba haciendo.'),
    GlossaryEntry('Guíame', 'Inicia o reanuda el recorrido guiado por la aplicación.'),
    GlossaryEntry('Probar conexión', 'Consulta el POS con la dirección escrita, sin guardarla.'),
    GlossaryEntry('Guardar borrador', 'Guarda lo escrito para continuar luego; no aplica cambios.'),
    GlossaryEntry('Aplicar cambios', 'Guarda y pone en uso la configuración inmediatamente.'),
    GlossaryEntry('Enviar a QuickBooks', 'Crea el asiento en QuickBooks. Siempre pide confirmación.'),
  ];

  static const shortcuts = <GlossaryEntry>[
    GlossaryEntry('F1', 'Abrir la ayuda de la pantalla actual.'),
    GlossaryEntry('Ctrl + Enter', 'Siguiente paso en los asistentes.'),
    GlossaryEntry('Esc', 'Cerrar diálogos y el panel de ayuda.'),
    GlossaryEntry('Tab / Shift + Tab', 'Moverse entre campos y botones.'),
  ];

  // -------------------------------------------------------------------------
  // Tutorials
  // -------------------------------------------------------------------------
  static const tutorials = <HelpArticle>[
    HelpArticle(
      id: 't-start',
      title: 'Primeros pasos',
      summary: 'Deje la aplicación lista en unos 10 minutos.',
      steps: [
        'Inicie sesión con el usuario admin y cambie la contraseña temporal.',
        'Abra el Asistente de configuración (se abre solo la primera vez).',
        'Escriba la IP y el puerto del POS y presione "Probar conexión".',
        'Guarde el Client ID / Client Secret de Intuit y presione "Conectar con QuickBooks".',
        'Asigne una cuenta a cada categoría en Mapeo de Cuentas.',
        'Opcional: programe un envío diario.',
      ],
      links: [HelpLink('Abrir asistente', Routes.asistente)],
    ),
    HelpArticle(
      id: 't-first-sync',
      title: 'Su primera sincronización',
      summary: 'Revise y envíe un día de ventas.',
      steps: [
        'Vaya a Vista Previa.',
        'En el paso 1 elija "Ayer" y presione Siguiente.',
        'En el paso 2 confirme que el asiento diga "Balanceado". Si falta alguna cuenta, use el botón que aparece.',
        'En el paso 3 presione "Enviar a QuickBooks" y confirme.',
        'Anote el número de asiento y revíselo en QuickBooks (Contabilidad → Asientos de diario).',
      ],
      links: [HelpLink('Ir a Vista Previa', Routes.vistaPrevia)],
    ),
    HelpArticle(
      id: 't-imbalance',
      title: 'Resolver un asiento que no cuadra',
      summary: 'Encuentre el día y la causa de la diferencia.',
      steps: [
        'En Vista Previa, paso 2, presione "Diagnosticar diferencia".',
        'Revise los días al inicio de la lista: son los de mayor diferencia.',
        'Compare la columna "Descuentos" y "Cobros cruzados": si explican la diferencia, la columna "Sin explicar" será 0.',
        'Use "Ver detalle" en ese día para ver los datos crudos del POS.',
        'Corrija en el POS si hace falta y vuelva a generar la vista previa.',
      ],
    ),
    HelpArticle(
      id: 't-pos-ip',
      title: 'Cambiar la IP del POS',
      summary: 'Cuando el servidor del POS cambia de dirección.',
      steps: [
        'Configuración → Acceso a la API del POS.',
        'Escriba la nueva IP y el puerto (o toque una dirección reciente).',
        'Presione "Probar conexión" y espere el mensaje verde.',
        'Presione "Aplicar cambios". No necesita reiniciar.',
      ],
      links: [HelpLink('Ir a Configuración', Routes.configuracion)],
    ),
    HelpArticle(
      id: 't-reconnect',
      title: 'Reconectar QuickBooks',
      summary: 'Si aparece "La autorización de QuickBooks ya no es válida".',
      steps: [
        'Configuración → QuickBooks Online.',
        'Presione "Conectar con QuickBooks"; se abrirá el navegador.',
        'Inicie sesión en Intuit, elija la compañía y presione "Conectar".',
        'Vuelva a RM Ledger Sync: verá el nombre de la compañía conectada.',
      ],
      links: [HelpLink('Ir a Configuración', Routes.configuracion)],
    ),
  ];

  // -------------------------------------------------------------------------
  // FAQ / troubleshooting
  // -------------------------------------------------------------------------
  static const faq = <FaqEntry>[
    FaqEntry(
      question: '"Conexión rechazada" al probar el POS',
      answer: 'El equipo existe pero el servicio de la API no responde en ese puerto.',
      fix: 'Verifique el puerto (normalmente 8180) y que el servicio del POS esté iniciado.',
      link: HelpLink('Configuración', Routes.configuracion),
    ),
    FaqEntry(
      question: '"Tiempo de espera agotado" o "No se pudo alcanzar"',
      answer: 'No hubo respuesta de la red.',
      fix: 'Confirme la IP, que ambos equipos estén en la misma red y que el firewall permita el puerto.',
      link: HelpLink('Configuración', Routes.configuracion),
    ),
    FaqEntry(
      question: '"No se encontró el equipo (error DNS)"',
      answer: 'El nombre del equipo no se pudo resolver.',
      fix: 'Use la dirección IP en lugar del nombre.',
    ),
    FaqEntry(
      question: 'La sincronización quedó "Omitida"',
      answer: 'Ya existe un envío exitoso que cubre parte de esas fechas; se evita duplicar ventas en QuickBooks.',
      fix: 'Si realmente necesita otro asiento (por ejemplo, borró el anterior en QuickBooks), use "Sincronizar de todas formas" en Vista Previa.',
      link: HelpLink('Ver Historial', Routes.historial),
    ),
    FaqEntry(
      question: '"El asiento no está balanceado"',
      answer: 'Las ventas del POS no suman lo mismo que los pagos en ese rango.',
      fix: 'Use "Diagnosticar diferencia" en Vista Previa y revise los días señalados.',
      link: HelpLink('Vista Previa', Routes.vistaPrevia),
    ),
    FaqEntry(
      question: '"Faltan cuentas en Mapeo de Cuentas"',
      answer: 'Una categoría con monto no tiene cuenta asignada.',
      fix: 'Asigne la cuenta en Mapeo de Cuentas.',
      link: HelpLink('Mapeo de Cuentas', Routes.mapeo),
    ),
    FaqEntry(
      question: '"Requieren un cliente o suplidor"',
      answer: 'QuickBooks exige un Cliente en líneas de Cuentas por Cobrar y un Suplidor en Cuentas por Pagar.',
      fix: 'En Mapeo de Cuentas elija el tipo de entidad y la entidad para esa categoría.',
      link: HelpLink('Mapeo de Cuentas', Routes.mapeo),
    ),
    FaqEntry(
      question: '"La autorización de QuickBooks ya no es válida"',
      answer: 'El permiso venció (más de 100 días sin uso) o fue revocado en Intuit.',
      fix: 'Reconecte desde Configuración.',
      link: HelpLink('Configuración', Routes.configuracion),
    ),
    FaqEntry(
      question: 'Error de QuickBooks "Business Validation Error"',
      answer: 'QuickBooks rechazó el asiento (cuenta inactiva, período cerrado, entidad requerida, etc.). El detalle aparece en el mensaje.',
      fix: 'Corrija la cuenta o el período en QuickBooks, actualice el mapeo y vuelva a intentar.',
    ),
    FaqEntry(
      question: 'No se ejecutó la sincronización programada',
      answer: 'La aplicación debe estar abierta (puede estar en la bandeja del sistema).',
      fix: 'Active "Iniciar con Windows" en Configuración. Al abrirla, los envíos atrasados se ejecutan solos.',
    ),
    FaqEntry(
      question: '¿Por qué no aparecen los descuentos en el asiento?',
      answer: 'La venta neta del POS ya viene después de descuentos; el total de descuentos se muestra solo como referencia.',
    ),
    FaqEntry(
      question: 'Olvidé mi contraseña',
      answer: 'Un administrador puede restablecerla en Usuarios. Si no hay otro administrador, contacte a soporte.',
    ),
  ];
}
