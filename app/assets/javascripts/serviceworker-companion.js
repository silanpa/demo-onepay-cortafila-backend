function UUID() {
  var d = new Date().getTime();
  var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = (d + Math.random() * 16) % 16 | 0;
    d = Math.floor(d / 16);
    return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
  });
  return uuid;
}

function postSubscription(sub) {
  var xhr = new XMLHttpRequest();
  var url = "/setup/register";
  xhr.open("POST", url, true);
  xhr.setRequestHeader("Content-Type", "application/json");
  xhr.onreadystatechange = function () {
      if (xhr.readyState === 4 && xhr.status === 200) {

      }
  };
  var data = JSON.stringify({ deviceid: deviceid, token: sub.toJSON(), source: "web"});
  xhr.send(data);
}

let deviceid = localStorage.getItem("deviceid");

if (deviceid === null) {
  deviceid = UUID();
  localStorage.setItem("deviceid", deviceid);
}

if (navigator.serviceWorker) {
  navigator.serviceWorker.register('/serviceworker.js', { scope: './' })
    .then(function(reg) {
      console.log('[Companion]', 'Service worker registered!');
      reg.pushManager.getSubscription().then(function(sub) {
        if (sub === null) {
          // Update UI to ask user to register for Push
          console.log('Not subscribed to push service!');
          subscribeUser();
        } else {
          // We have a subscription, update the database
          postSubscription(sub);
          $('#overlay-permission').hide();
        }
      });
    });
}

function subscribeUser() {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.ready.then(function(reg) {

      reg.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: window.vapidPublicKey
      }).then(function(sub) {
        console.log('Endpoint URL: ', sub.endpoint);
        $('#overlay-permission').hide();
        postSubscription(sub);
      }).catch(function(e) {
        if (Notification.permission === 'denied') {
          $('#overlay-permission').show();
          $('#overlay-message').text("Los permisos de notificación han sido rechazados, por favor aceptalos");
          console.warn('Permission for notifications was denied');
        } else {
          console.error('Unable to subscribe to push', e);
          $('#overlay-permission').show();
          $('#overlay-message').text("Los permisos de notificación han sido rechazados, por favor aceptalos");
        }
      });
    })
  }
}
