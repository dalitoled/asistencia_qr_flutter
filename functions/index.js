const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { CronJob } = require('cron');

admin.initializeApp();

const db = admin.firestore();

// Función para generar faltantes automáticamente
exports.generarFaltasDiarias = functions.pubsub
  .schedule('0 0 * * *') // Corre a medianoche cada día
  .timeZone('America/La_Paz')
  .onRun(async (context) => {
    try {
      const ahora = new Date();
      const inicioDia = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
      const finDia = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate(), 23, 59, 59);

      // Obtener todos los socios activos
      const sociosSnapshot = await db.collection('socios')
        .where('estado', '==', true)
        .get();

      // Obtener configuraciones
      const configDoc = await db.collection('configuraciones').doc('default').get();
      const config = configDoc.exists ? configDoc.data() : { multaFalta: 25 };

      const asistentesDelDia = [];

      // Obtener registros de asistencia del día
      const asistenciaSnapshot = await db.collection('asistencias')
        .where('fechaHora', '>=', inicioDia)
        .where('fechaHora', '<=', finDia)
        .get();

      asistenciaSnapshot.forEach(doc => {
        asistentesDelDia.push(doc.data().socioId);
      });

      // Para cada socio activo, verificar si registró asistencia
      const batch = db.batch();
      
      for (const socioDoc of sociosSnapshot.docs) {
        const socioData = socioDoc.data();
        
        // Si el socio no asistió hoy, crear una falta
        if (!asistentesDelDia.includes(socioDoc.id)) {
          const faltaRef = db.collection('multas').doc();
          batch.set(faltaRef, {
            uid: faltaRef.id,
            socioId: socioDoc.id,
            socioNombre: socioData.nombreCompleto,
            tipo: 'falta',
            monto: config.multaFalta || 25,
            estado: 'pendiente',
            fecha: admin.firestore.Timestamp.now(),
            observaciones: 'Falta automática generada por no registrar asistencia',
            source: 'automatic'
          });
        }
      }

      await batch.commit();
      console.log('Faltas generadas automáticamente');
      return null;
    } catch (error) {
      console.error('Error al generar faltantes:', error);
      return null;
    }
  });

// Función para enviar recordatorio de reunión
exports.enviarRecordatorioReunion = functions.pubsub
  .schedule('0 8 * * 0') // Corre a las 8 AM los domingos
  .timeZone('America/La_Paz')
  .onRun(async (context) => {
    try {
      const message = {
        notification: {
          title: 'Recordatorio de Reunión',
          body: 'Este domingo hay reunión de la Asociación. No olvide asistir.',
        },
        topic: 'recordatorios'
      };

      await admin.messaging().send(message);
      console.log('Recordatorio enviado');
      return null;
    } catch (error) {
      console.error('Error al enviar recordatorio:', error);
      return null;
    }
  });

// Función para notificar multas pendientes
exports.notificarMultasPendientes = functions.pubsub
  .schedule('0 18 * * *') // Corre a las 6 PM diariamente
  .timeZone('America/La_Paz')
  .onRun(async (context) => {
    try {
      const multasSnapshot = await db.collection('multas')
        .where('estado', '==', 'pendiente')
        .get();

      if (multasSnapshot.empty) {
        return null;
      }

      const mensajesPorSocio = {};

      multasSnapshot.forEach(doc => {
        const multa = doc.data();
        if (!mensajesPorSocio[multa.socioId]) {
          mensajesPorSocio[multa.socioId] = [];
        }
        mensajesPorSocio[multa.socioId].push(multa);
      });

      for (const [socioId, multas] of Object.entries(mensajesPorSocio)) {
        const total = multas.reduce((sum, m) => sum + m.monto, 0);
        
        const message = {
          notification: {
            title: 'Tiene multas pendientes',
            body: `Tiene ${multas.length} multa(s) pendiente(s) por un total de Bs. ${total.toFixed(2)}`,
          },
          topic: `socio_${socioId}`
        };

        await admin.messaging().send(message);
      }

      console.log('Notificaciones de multas enviadas');
      return null;
    } catch (error) {
      console.error('Error al notificar multas:', error);
      return null;
    }
  });

// Función HTTP para validar código QR
exports.validarQrCode = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Debe autenticarse');
  }

  const { qrData } = data;

  if (!qrData) {
    throw new functions.https.HttpsError('invalid-argument', 'Código QR requerido');
  }

  try {
    const parts = qrData.split('|');
    if (parts.length !== 3) {
      return { valido: false, mensaje: 'Formato de código QR inválido' };
    }

    const socioId = parts[0];
    const socioDoc = await db.collection('socios').doc(socioId).get();

    if (!socioDoc.exists) {
      return { valido: false, mensaje: 'Socio no encontrado' };
    }

    const socioData = socioDoc.data();
    
    if (!socioData.estado) {
      return { valido: false, mensaje: 'Socio inactivo' };
    }

    // Verificar si ya registró asistencia hoy
    const ahora = new Date();
    const inicioDia = new Date(ahora.getFullYear(), ahora.getMonth(), hoy = ahora.getDate());
    const finDia = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate(), 23, 59, 59);

    const asistenciaExistente = await db.collection('asistencias')
      .where('socioId', '==', socioId)
      .where('fechaHora', '>=', inicioDia)
      .where('fechaHora', '<=', finDia)
      .limit(1)
      .get();

    if (!asistenciaExistente.empty) {
      return { 
        valido: false, 
        mensaje: 'Ya registró asistencia hoy',
        tipo: asistenciaExistente.docs[0].data().tipo
      };
    }

    return {
      valido: true,
      socio: {
        id: socioId,
        nombre: socioData.nombreCompleto,
        ci: socioData.ci
      }
    };
  } catch (error) {
    console.error('Error al validar QR:', error);
    throw new functions.https.HttpsError('internal', 'Error al validar código QR');
  }
});

// Función para registrar asistencia con validación
exports.registrarAsistencia = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Debe autenticarse');
  }

  const { socioId, operadorId } = data;

  if (!socioId || !operadorId) {
    throw new functions.https.HttpsError('invalid-argument', 'Datos requeridos');
  }

  try {
    const socioDoc = await db.collection('socios').doc(socioId).get();
    
    if (!socioDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Socio no encontrado');
    }

    const socioData = socioDoc.data();

    // Verificar asistencia del día
    const ahora = new Date();
    const inicioDia = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate());
    const finDia = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate(), 23, 59, 59);

    const asistenciaExistente = await db.collection('asistencias')
      .where('socioId', '==', socioId)
      .where('fechaHora', '>=', inicioDia)
      .where('fechaHora', '<=', finDia)
      .limit(1)
      .get();

    if (!asistenciaExistente.empty) {
      throw new functions.https.HttpsError('already-exists', 'Ya registró asistencia hoy');
    }

    // Obtener configuración para determinar tipo
    const configDoc = await db.collection('configuraciones').doc('default').get();
    const config = configDoc.exists ? configDoc.data() : { horaLimite: '08:00', multaRetraso: 10 };
    
    const horaLimite = config.horaLimite ? config.horaLimite.split(':') : ['08', '00'];
    const limite = new Date(ahora.getFullYear(), ahora.getMonth(), ahora.getDate(), 
      parseInt(horaLimite[0]), parseInt(horaLimite[1]));
    
    const tipo = ahora > limite ? 'retraso' : 'asistencia';

    const asistenciaRef = db.collection('asistencias').doc();
    await asistenciaRef.set({
      uid: asistenciaRef.id,
      socioId,
      socioNombre: socioData.nombreCompleto,
      socioCi: socioData.ci,
      tipo,
      fechaHora: admin.firestore.Timestamp.now(),
      operadorId
    });

    let resultado = { success: true, tipo };

    // Si es retraso, crear multa automáticamente
    if (tipo === 'retraso') {
      const multaRef = db.collection('multas').doc();
      await multaRef.set({
        uid: multaRef.id,
        socioId,
        socioNombre: socioData.nombreCompleto,
        tipo: 'retraso',
        monto: config.multaRetraso || 10,
        estado: 'pendiente',
        fecha: admin.firestore.Timestamp.now(),
        observaciones: 'Multa automática por retraso',
        asistenciaId: asistenciaRef.id
      });
      resultado.multaId = multaRef.id;
    }

    return resultado;
  } catch (error) {
    console.error('Error al registrar asistencia:', error);
    throw new functions.https.HttpsError('internal', 'Error al registrar asistencia');
  }
});