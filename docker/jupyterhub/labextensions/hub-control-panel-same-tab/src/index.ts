import { JupyterFrontEnd, JupyterFrontEndPlugin } from '@jupyterlab/application';

const plugin: JupyterFrontEndPlugin<void> = {
  id: 'hub-control-panel-same-tab:plugin',
  autoStart: true,
  activate: (app: JupyterFrontEnd) => {
    // Finn hubPrefix fra DOM-konfig
    let hubPrefix = '/hub/';
    const el = document.getElementById('jupyter-config-data');
    if (el) {
      try {
        const cfg = JSON.parse(el.textContent || '{}');
        if (cfg && typeof cfg.hubPrefix === 'string') {
          hubPrefix = cfg.hubPrefix;
        }
      } catch {
        /* ignore */
      }
    }

    // Monkey-patch window.open for å åpne Hub i samme fane
    const guard = '__hubSameTabPatched__';
    const w = window as unknown as Record<string, unknown>;
    if (!w[guard]) {
      const originalOpen = window.open.bind(window);
      window.open = ((url: string | URL, target?: string, features?: string) => {
        const s = typeof url === 'string' ? url : url.toString();
        if (s.includes(`${hubPrefix}home`)) {
          window.location.assign(s);
          return null;
        }
        return originalOpen(url as any, target, features);
      }) as typeof window.open;
      w[guard] = true;
    }
  }
};

export default plugin;


