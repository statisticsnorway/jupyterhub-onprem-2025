import { JupyterFrontEnd, JupyterFrontEndPlugin } from '@jupyterlab/application';

const plugin: JupyterFrontEndPlugin<void> = {
  id: 'hub-control-panel-same-tab:plugin',
  autoStart: true,
  activate: (app: JupyterFrontEnd) => {
    const cmd = 'hub:control-panel';
    // If the command exists, override it to open in same tab
    if (app.commands.hasCommand(cmd)) {
      app.commands.addCommand(cmd, {
        label: 'Hub Control Panel',
        execute: () => {
          // Read config from the DOM to avoid depending on @jupyterlab/coreutils
          let hubPrefix = '/hub/';
          const el = document.getElementById('jupyter-config-data');
          if (el) {
            try {
              const cfg = JSON.parse(el.textContent || '{}');
              if (cfg && typeof cfg.hubPrefix === 'string') {
                hubPrefix = cfg.hubPrefix;
              }
            } catch {
              /* ignore parse errors */
            }
          }
          // Navigate in the same tab
          window.location.assign(`${hubPrefix}home`);
        }
      });
    }
  }
};

export default plugin;


