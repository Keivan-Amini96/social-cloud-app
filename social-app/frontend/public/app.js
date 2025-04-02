const firebaseConfig = {
    apiKey: "AIzaSy...",
    authDomain: "p-group-18.firebaseapp.com",
    projectId: "p-group-18",
    storageBucket: "p-group-18.appspot.com"
  };
  
  // Initialize Firebase
  firebase.initializeApp(firebaseConfig);
  const auth = firebase.auth();
  const storage = firebase.storage();
  const database = firebase.database();
  
  /***** AUTHENTICATION *****/
  let currentUser = null;
  
  // Auth state listener
  auth.onAuthStateChanged(user => {
    currentUser = user;
    updateAuthUI();
  });
  
  function updateAuthUI() {
    const authStatus = document.getElementById('auth-status');
    if (currentUser) {
      authStatus.innerHTML = `Welcome, ${currentUser.email}!`;
      document.getElementById('auth-form').style.display = 'none';
      document.getElementById('upload-section').style.display = 'block';
    } else {
      authStatus.innerHTML = 'Please sign in';
      document.getElementById('auth-form').style.display = 'block';
      document.getElementById('upload-section').style.display = 'none';
    }
  }
  
  // Login function
  function login() {
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    auth.signInWithEmailAndPassword(email, password)
      .catch(error => {
        document.getElementById('auth-error').textContent = error.message;
      });
  }
  
  // Logout function
  function logout() {
    auth.signOut();
  }
  
  /***** IMAGE UPLOAD *****/
  document.getElementById('upload-form').addEventListener('submit', (e) => {
    e.preventDefault();
    
    const file = document.getElementById('image-upload').files[0];
    if (!file) return;
  
    // Create storage reference
    const storageRef = storage.ref(`images/${currentUser.uid}/${file.name}`);
    
    // Upload file
    storageRef.put(file)
      .then(snapshot => {
        console.log('Uploaded file!');
        return snapshot.ref.getDownloadURL();
      })
      .then(url => {
        document.getElementById('image-preview').innerHTML = `
          <img src="${url}" width="200">
          <p>Upload successful!</p>
        `;
      })
      .catch(error => {
        console.error('Upload failed:', error);
      });
  });
  
  /***** INITIALIZE APP *****/
  document.addEventListener('DOMContentLoaded', () => {
    updateAuthUI();
  });
const storage = firebase.storage();

function uploadPhoto() {
  const file = document.getElementById('photo-upload').files[0];
  if (!file) {
    alert('Please select a file first!');
    return;
  }

  // Create reference with user-specific path
  const storageRef = storage.ref(`photos/${firebase.auth().currentUser.uid}/${Date.now()}_${file.name}`);
  
  // Show loading state
  document.getElementById('photo-preview').innerHTML = 'Uploading...';
  
  // Upload file
  storageRef.put(file)
    .then(snapshot => {
      console.log(`Uploaded ${file.name}`);
      return snapshot.ref.getDownloadURL();
    })
    .then(url => {
      document.getElementById('photo-preview').innerHTML = `
        <img src="${url}" class="uploaded-image">
        <p>Upload successful!</p>
        <input type="hidden" id="photo-url" value="${url}">
      `;
    })
    .catch(error => {
      console.error("Upload failed:", error);
      document.getElementById('photo-preview').innerHTML = `
        <p style="color:red">Upload failed: ${error.message}</p>
      `;
    });
}
