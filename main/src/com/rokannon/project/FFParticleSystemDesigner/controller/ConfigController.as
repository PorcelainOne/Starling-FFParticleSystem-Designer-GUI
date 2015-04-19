package com.rokannon.project.FFParticleSystemDesigner.controller
{
    import com.rokannon.core.command.enum.CommandState;
    import com.rokannon.core.utils.getProperty;
    import com.rokannon.core.utils.requireProperty;
    import com.rokannon.project.FFParticleSystemDesigner.ApplicationView;
    import com.rokannon.project.FFParticleSystemDesigner.controller.enum.ErrorMessage;
    import com.rokannon.project.FFParticleSystemDesigner.controller.enum.ErrorTitle;
    import com.rokannon.project.FFParticleSystemDesigner.controller.fileLoad.FileLoadCommand;
    import com.rokannon.project.FFParticleSystemDesigner.controller.fileLoad.FileLoadCommandData;
    import com.rokannon.project.FFParticleSystemDesigner.controller.fileSave.FileSaveCommand;
    import com.rokannon.project.FFParticleSystemDesigner.controller.fileSave.FileSaveCommandData;
    import com.rokannon.project.FFParticleSystemDesigner.model.ApplicationModel;

    import feathers.controls.Alert;
    import feathers.data.ListCollection;

    import flash.filesystem.File;
    import flash.utils.ByteArray;

    import starling.events.Event;

    public class ConfigController
    {
        private var _appModel:ApplicationModel;
        private var _appView:ApplicationView;
        private var _appController:ApplicationController;

        public function ConfigController()
        {
        }

        public function connect(appModel:ApplicationModel, appView:ApplicationView,
                                appController:ApplicationController):void
        {
            _appModel = appModel;
            _appView = appView;
            _appController = appController;
        }

        public function loadConfig():Boolean
        {
            _appModel.commandExecutor.pushMethod(doLoadConfig);
            return true;
        }

        public function saveConfig():Boolean
        {
            _appModel.commandExecutor.pushMethod(doSaveConfig);
            return true;
        }

        private function doLoadConfig():Boolean
        {
            var fileLoadCommandData:FileLoadCommandData = new FileLoadCommandData();
            fileLoadCommandData.fileModel = _appModel.fileModel;
            fileLoadCommandData.fileToLoad = File.applicationStorageDirectory.resolvePath("config.json");
            _appModel.commandExecutor.pushCommand(new FileLoadCommand(fileLoadCommandData), CommandState.COMPLETE);
            _appModel.commandExecutor.pushMethod(parseConfig, CommandState.COMPLETE);
            _appModel.commandExecutor.pushMethod(handleParseError, CommandState.FAILED);
            return true;
        }

        private function parseConfig():Boolean
        {
            try
            {
                var json:Object = JSON.parse(_appModel.fileModel.fileContent.toString());
                _appModel.particleModel.particleDirectory = File.applicationStorageDirectory.resolvePath(requireProperty(json,
                    "particleDirectory"));
                _appModel.particleModel.appendFromObject = getProperty(json, "appendFromObject", null);
            }
            catch (error:Error)
            {
                return false;
            }
            return true;
        }

        private function handleParseError():Boolean
        {
            _appModel.commandExecutor.removeAllCommands();
            var buttonCollection:ListCollection = new ListCollection([{label: "Reset"}, {label: "Close"}]);
            var alert:Alert = Alert.show(ErrorMessage.BAD_CONFIG, ErrorTitle.ERROR, buttonCollection);
            alert.addEventListener(Event.CLOSE, function (event:Event):void
            {
                if (event.data.label == "Reset")
                    _appController.resetParticleSystem();
            });
            return false;
        }

        private function doSaveConfig():Boolean
        {
            if (_appModel.particleModel.particleDirectory == null)
                return false; // Nothing to save.
            var config:Object = {};
            config.particleDirectory = _appModel.particleModel.particleDirectory.nativePath;
            if (_appModel.particleModel.appendFromObject != null)
                config.appendFromObject = _appModel.particleModel.appendFromObject;
            var bytes:ByteArray = new ByteArray();
            bytes.writeUTFBytes(JSON.stringify(config));
            var fileSaveCommandData:FileSaveCommandData = new FileSaveCommandData();
            fileSaveCommandData.bytesToWrite = bytes;
            fileSaveCommandData.fileToSaveTo = File.applicationStorageDirectory.resolvePath("config.json");
            _appModel.commandExecutor.pushCommand(new FileSaveCommand(fileSaveCommandData), CommandState.COMPLETE);
            return true;
        }
    }
}