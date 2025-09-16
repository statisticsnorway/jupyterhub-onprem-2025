import { JupyterFrontEnd, JupyterFrontEndPlugin } from '@jupyterlab/application';
import { PageConfig } from '@jupyterlab/coreutils';

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
          const hubPrefix = PageConfig.getOption('hubPrefix') || '/hub/';
          // Navigate in the same tab
          window.location.assign(`${hubPrefix}home`);
        }
      });
    }
  }
};

export default plugin;


