importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyCejR8bIwYpHyKEAfAe_TKWyTIpPkLZDD4',
  appId: '1:515375750675:android:488d87b6faf327e02029e6',
  messagingSenderId: '515375750675',
  projectId: 'campusnotify-50757',
  storageBucket: 'campusnotify-50757.firebasestorage.app',
});

firebase.messaging();
