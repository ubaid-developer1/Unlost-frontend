import firebase from "firebase/app";
import "firebase/auth";

const firebaseConfig = {
    apiKey: "AIzaSyAKP2brsj54BZU0Umibznc2_aGWi0InhQ0",
    authDomain: "un-lost-be18c.firebaseapp.com",
    projectId: "un-lost-be18c",
    storageBucket: "un-lost-be18c.firebasestorage.app",
    messagingSenderId: "1076758987181",
    appId: "1:1076758987181:web:7ded03c307cf6342c02124",
    measurementId: "G-0M10ZY8FS5"
  };


firebase.initializeApp(firebaseConfig);


export default firebase;
