// Script para crear administrador - Solo ejecutar desde máquina del desarrollador
const admin = require('firebase-admin');

// Inicializar Firebase Admin (requiere service account key)
const serviceAccount = require('./service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://flutter-template-826b1-default-rtdb.firebaseio.com/'
});

async function makeUserAdmin(email) {
  try {
    // Buscar usuario por email
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;
    
    // Asignar rol de admin en database
    await admin.database().ref(`users/${uid}/roles`).set(['admin']);
    
    console.log(`✅ Usuario ${email} (${uid}) ahora es administrador`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

// Usar: node admin_setup.js usuario@email.com
const email = process.argv[2];
if (!email) {
  console.log('Uso: node admin_setup.js usuario@email.com');
  process.exit(1);
}

makeUserAdmin(email);
