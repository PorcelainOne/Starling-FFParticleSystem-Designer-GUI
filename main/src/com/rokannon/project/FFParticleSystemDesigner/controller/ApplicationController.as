package com.rokannon.project.FFParticleSystemDesigner.controller
{
    import com.rokannon.math.utils.getMax;
    import com.rokannon.project.FFParticleSystemDesigner.ApplicationView;
    import com.rokannon.project.FFParticleSystemDesigner.controller.directoryListing.DirectoryListingCommand;
    import com.rokannon.project.FFParticleSystemDesigner.controller.directoryListing.DirectoryListingCommandData;
    import com.rokannon.project.FFParticleSystemDesigner.model.ApplicationModel;

    import de.flintfabrik.starling.display.FFParticleSystem;

    import flash.filesystem.File;

    public class ApplicationController
    {
        public const configController:ConfigController = new ConfigController();
        public const localStorageController:LocalStorageController = new LocalStorageController();
        public const particleSystemController:ParticleSystemController = new ParticleSystemController();

        private var _appModel:ApplicationModel;
        private var _appView:ApplicationView;

        public function ApplicationController()
        {
        }

        public function connect(appModel:ApplicationModel, appView:ApplicationView):void
        {
            _appModel = appModel;
            _appView = appView;
            configController.connect(_appModel, _appView, this);
            localStorageController.connect(_appModel, _appView, this);
            particleSystemController.connect(_appModel, _appView, this);
        }

        public function startApplication():void
        {
            _appModel.commandExecutor.pushMethod(doStartApplication);
        }

        public function resetError():Boolean
        {
            return true;
        }

        private function doStartApplication():Boolean
        {
            _appModel.commandExecutor.eventExecuteStart.add(_appView.lockButtons);
            _appModel.commandExecutor.eventExecuteEnd.add(_appView.unlockButtons);
            if (_appModel.commandExecutor.isExecuting)
                _appView.lockButtons();

            FFParticleSystem.init(4096, false, 4096, 16);

            localStorageController.setupLocalStorage(true, false);
            configController.loadConfig(true);
            particleSystemController.loadParticleSystem(true);
            _appModel.starlingInstance.juggler.add(_appModel.particleUpdateModel);
            _appModel.particleUpdateModel.eventUpdated.add(handlePexUpdate);
            return true;
        }

        private function handlePexUpdate():void
        {
            if (_appModel.commandExecutor.isExecuting)
                return;
            updateModificationTime();
            _appModel.commandExecutor.pushMethod(doPexUpdate);
        }

        private function doPexUpdate():Boolean
        {
            if (_appModel.particleModel.particleModificationTime > _appModel.particleModel.particleLoadTime)
                particleSystemController.loadParticleSystem(false);
            return true;
        }

        public function updateModificationTime():void
        {
            _appModel.commandExecutor.pushMethod(doUpdateModificationTime_step1);
        }

        private function doUpdateModificationTime_step1():Boolean
        {
            var directoryListingCommandData:DirectoryListingCommandData = new DirectoryListingCommandData();
            directoryListingCommandData.directoryToLoad = _appModel.particleModel.particleDirectory;
            directoryListingCommandData.fileModel = _appModel.fileModel;
            _appModel.commandExecutor.pushCommand(new DirectoryListingCommand(directoryListingCommandData));
            _appModel.commandExecutor.pushMethod(handleDirectoryListingError, false);
            _appModel.commandExecutor.pushMethod(doUpdateModificationTime_step2);
            return true;
        }

        private function handleDirectoryListingError():Boolean
        {
            _appModel.commandExecutor.removeAllCommands();
            return true;
        }

        private function doUpdateModificationTime_step2():Boolean
        {
            var time:Number = 0;
            for each (var file:File in _appModel.fileModel.directoryListing)
                time = getMax(time, file.modificationDate.getTime());
            _appModel.particleModel.particleModificationTime = time;
            return true;
        }
    }
}