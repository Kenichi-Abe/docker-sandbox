(function () {
  function enableRememberMeByDefault() {
    var rememberMe = document.querySelector('input[name="rememberMe"]');
    if (rememberMe) {
      rememberMe.checked = true;
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', enableRememberMeByDefault, { once: true });
  } else {
    enableRememberMeByDefault();
  }
})();
