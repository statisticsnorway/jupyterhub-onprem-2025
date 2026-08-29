"""Send RStudio Sign Out / Quit Session back to the JupyterHub control panel.

RStudio open-source has no Hub-aware logout URL. jupyter-rsession-proxy
starts rserver with auth-none, so Sign Out and Quit Session stay inside
/rstudio/. Rewrite those flows to /hub/home (JupyterHub Control Panel).

jupyter-server-proxy rewrites *relative* Location headers by prefixing the
proxy path (e.g. /hub/home -> /user/<name>/rstudio/hub/home). That yields
RStudio's own 404 page ("The requested page was not found"). Absolute
URLs (scheme + host) are left untouched. See
https://github.com/jupyterhub/jupyter-server-proxy/blob/main/jupyter_server_proxy/handlers.py
(_rewrite_location_header).
"""

import jupyter_rsession_proxy

_HUB_PATH = "/hub/home"
_orig_setup = jupyter_rsession_proxy.setup_rserver

_INJECT = """<script id="jupyterhub-return-hook">
(function () {
  var hub = window.location.origin + "/hub/home";
  function goHub() {
    try { window.top.location.assign(hub); }
    catch (e) { window.location.assign(hub); }
  }
  function watch(url) {
    if (/auth-sign-out|quit_session|sign_out/i.test(String(url || ""))) {
      setTimeout(goHub, 300);
    }
  }
  var xhrOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    this.addEventListener("load", function () { watch(url); });
    return xhrOpen.apply(this, arguments);
  };
  if (window.fetch) {
    var origFetch = window.fetch;
    window.fetch = function (input, init) {
      var url = typeof input === "string" ? input : (input && input.url);
      return origFetch.apply(this, arguments).then(function (res) {
        watch(url);
        return res;
      });
    };
  }
  document.addEventListener("click", function (ev) {
    var a = ev.target && ev.target.closest && ev.target.closest("a[href]");
    if (a && /auth-sign-out/i.test(a.getAttribute("href") || "")) {
      ev.preventDefault();
      goHub();
    }
  }, true);
})();
</script>
""".encode()


def _absolute_hub_home(request=None):
    """Return an absolute Control Panel URL so the proxy will not rewrite it."""
    proto = "http"
    host = ""
    if request is not None:
        headers = getattr(request, "headers", None) or {}
        forwarded_host = headers.get("X-Forwarded-Host") or headers.get("Host")
        if forwarded_host:
            host = forwarded_host.split(",")[0].strip()
        if not host:
            host = getattr(request, "host", "") or ""
        forwarded_proto = headers.get("X-Forwarded-Proto") or ""
        if forwarded_proto:
            proto = forwarded_proto.split(",")[0].strip()
        else:
            proto = getattr(request, "protocol", None) or "http"
    if host:
        return f"{proto}://{host}{_HUB_PATH}"
    return _HUB_PATH


def _rewrite(response, request=None, path="", **_kwargs):
    if request is not None:
        jupyter_rsession_proxy.rewrite_netloc(response, request)

    req_path = path or ""
    if request is not None:
        req_path = req_path or getattr(request, "path", "") or getattr(request, "uri", "")

    headers = getattr(response, "headers", None)
    location = ""
    if headers is not None:
        location = headers.get("Location") or ""

    if "auth-sign-out" in f"{req_path} {location}".lower():
        response.code = 302
        response.headers["Location"] = _absolute_hub_home(request)
        response.body = b""
        return

    body = getattr(response, "body", None) or b""
    content_type = (headers.get("Content-Type") or "") if headers is not None else ""
    if (
        isinstance(body, (bytes, bytearray))
        and "text/html" in content_type.lower()
        and b"</body>" in body
        and b"jupyterhub-return-hook" not in body
    ):
        response.body = body.replace(b"</body>", _INJECT + b"</body>", 1)
        if headers is not None:
            try:
                headers["Content-Length"] = str(len(response.body))
            except Exception:
                pass


def _setup_rserver(*args, **kwargs):
    spec = _orig_setup(*args, **kwargs)
    spec["rewrite_response"] = _rewrite
    return spec


jupyter_rsession_proxy.setup_rserver = _setup_rserver
