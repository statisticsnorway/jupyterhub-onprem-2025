import { JupyterFrontEnd, JupyterFrontEndPlugin } from '@jupyterlab/application';
import { IMainMenu } from '@jupyterlab/mainmenu';

const plugin: JupyterFrontEndPlugin<void> = {
  id: 'hub-control-panel-same-tab:plugin',
  autoStart: true,
  requires: [IMainMenu],
  activate: (app: JupyterFrontEnd, mainMenu: IMainMenu) => {
    const cmd = 'hub:control-panel';
    // Force add/override our command
    app.commands.addCommand(cmd, {
      label: 'Hub Control Panel',
      isEnabled: () => true,
      execute: () => {
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
        // same-tab navigation
        window.location.assign(`${hubPrefix}home`);
      }
    });

    // Legg det inn i File-menyen som første element i en egen gruppe
    mainMenu.fileMenu.addGroup([{ command: cmd }], 0);
  }
};

export default plugin;


