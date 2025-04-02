const firebaseConfig = {
  apiKey: "AIzaSyYOUR_API_KEY",
  authDomain: "p-9016-group-18.firebaseapp.com",
  projectId: "p-9016-group-18",
  storageBucket: "p-9016-group-18.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "1:YOUR_APP_ID"
};
const app = firebase.initializeApp(firebaseConfig);
console.log("Firebase initialized for project p-9016-group-18");
// Initialize Database Connection
async function initDB() {
  try {
    const response = await fetch('/api/init-db', {
      method: 'POST'
    });
    console.log(await response.json());
  } catch (err) {
    console.error("DB Init Failed:", err);
  }
}
initDB();
