package
{
   import Shared.*;
   import Shared.AS3.*;
   import Shared.AS3.Data.*;
   import Shared.AS3.Events.*;
   import com.adobe.serialization.json.*;
   import fl.motion.*;
   import flash.display.*;
   import flash.events.*;
   import flash.filters.*;
   import flash.geom.*;
   import flash.net.*;
   import flash.system.*;
   import flash.text.*;
   import flash.ui.*;
   import flash.utils.*;
   import scaleform.gfx.*;
   import utils.*;
   
   public class CustomRadios extends MovieClip
   {
      
      public static const MOD_NAME:String = "CustomRadios";
      
      public static const MOD_VERSION:String = "1.0.5";
      
      public static const FULL_MOD_NAME:String = MOD_NAME + " " + MOD_VERSION;
      
      public static const CONFIG_FILE:String = "../CustomRadios.json";
      
      public static const CONFIG_RELOAD_TIME:uint = 11000;
      
      private static const STRING_NUMBER_OF_TRACKS:String = "{numberOfTracks}";
      
      private static const STRING_RADIO_NAME:String = "{radioName}";
      
      private static const STRING_NEXT_RADIO_NAME:String = "{nextRadioName}";
      
      private static const STRING_TRACK_ID:String = "{trackId}";
      
      private static const STRING_TRACK_NAME:String = "{trackName}";
      
      private static const STRING_NEXT_TRACK_NAME:String = "{nextTrackName}";
      
      private static const STRING_TRACK_DURATION:String = "{trackDuration}";
      
      private static const STRING_ELAPSED_DURATION:String = "{elapsedDuration}";
      
      private static const STRING_HOTKEY:String = "{hotkey}";
      
      private static const TITLE_HUDMENU:String = "HUDMenu";
      
      private static const TITLE_OVERLAY:String = "OverlayMenu";
      
      private static const MAIN_MENU:String = "MainMenu";
      
      private static const HUDTOOLS_MENU_HIDE:String = MOD_NAME + "_HIDE";
      
      private static const HUDTOOLS_MENU_PLAY_PAUSE:String = MOD_NAME + "_PLAY_PAUSE";
      
      private static const HUDTOOLS_MENU_NEXT_SONG:String = MOD_NAME + "_NEXT_SONG";
      
      private static const HUDTOOLS_MENU_PREV_SONG:String = MOD_NAME + "_PREV_SONG";
      
      private static const HUDTOOLS_MENU_NEXT_RADIO:String = MOD_NAME + "_NEXT_RADIO";
      
      private static const HUDTOOLS_MENU_PREV_RADIO:String = MOD_NAME + "_PREV_RADIO";
      
      private static const HUDTOOLS_MENU_RELOAD_CONFIG:String = MOD_NAME + "_RELOAD_CONFIG";
      
      private var lastRenderTime:Number = 0;
      
      private var topLevel:* = null;
      
      private var isHudMenu:Boolean = false;
      
      private var dummy_tf:TextField;
      
      private var textFormat:TextFormat;
      
      private var timer:Timer;
      
      private var configTimer:Timer;
      
      private var displayTimer:Timer;
      
      private var lastConfig:String;
      
      private var HUDModeData:*;
      
      private var arrTextfields:Array = [];
      
      private var textfield_index:int = 0;
      
      private var yOffset:Number = 0;
      
      private var currentRadio:*;
      
      private var currentSong:*;
      
      private var currentSongPlayTimestamp:Number = 0;
      
      private var currentSongId:int = 0;
      
      private var currentRadioId:int = 0;
      
      private var skipSongs:int = 0;
      
      private var nextSongId:int = -1;
      
      private var radioButtons:Array = [];
      
      private const buttonActions:Array = CustomRadiosConfig.BUTTON_ACTIONS;
      
      private var refreshButtons:Boolean = false;
      
      private var isInMainMenu:Boolean = true;
      
      private var isServerHop:Boolean = false;
      
      private var nextSongUID:uint;
      
      private var hudTools:SharedHUDTools;
      
      private var forceHide:Boolean = false;
      
      private var isKeyDownDetected:Object = {};
      
      public function CustomRadios()
      {
         super();
         addEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler,false,0,true);
         this.HUDModeData = BSUIDataManager.GetDataFromClient("HUDModeData");
      }
      
      public static function toString(param1:Object) : String
      {
         return new JSONEncoder(param1).getString();
      }
      
      public static function ShowHUDMessage(param1:String) : void
      {
         GlobalFunc.ShowHUDMessage("[" + FULL_MOD_NAME + "] " + param1);
      }
      
      public function addedToStageHandler(param1:Event) : *
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler);
         addEventListener(Event.REMOVED_FROM_STAGE,this.removedFromStageHandler,false,0,true);
         var movieRoot:* = stage.getChildAt(0);
         if(Boolean(movieRoot))
         {
            this.topLevel = movieRoot;
            if(getQualifiedClassName(this.topLevel) == TITLE_HUDMENU)
            {
               this.isHudMenu = true;
               this.hudTools = new SharedHUDTools(MOD_NAME);
               this.hudTools.RegisterMenu(this.onBuildMenu,this.onSelectMenu);
            }
            else if(this.topLevel.numChildren > 0)
            {
               if(getQualifiedClassName(this.topLevel.getChildAt(0)) == TITLE_OVERLAY)
               {
                  this.topLevel = this.topLevel.getChildAt(0);
                  this.isHudMenu = false;
                  this.isInMainMenu = true;
                  BSUIDataManager.Subscribe("MenuStackData",this.updateIsMainMenu);
                  stage.addEventListener(KeyboardEvent.KEY_DOWN,this.keyDownHandler,false,0,true);
                  stage.addEventListener(KeyboardEvent.KEY_UP,this.keyUpHandler,false,0,true);
               }
            }
            this.initConfigTimer();
            this.loadConfig();
            trace(MOD_NAME + " added to stage: " + getQualifiedClassName(this.topLevel));
         }
         else
         {
            trace(MOD_NAME + " not added to stage: " + getQualifiedClassName(movieRoot));
            ShowHUDMessage("Not added to stage: " + getQualifiedClassName(movieRoot));
         }
      }
      
      public function removedFromStageHandler(param1:Event) : *
      {
         clearTimeout(nextSongUID);
         BSUIDataManager.Unsubscribe("MenuStackData",this.updateIsMainMenu);
         removeEventListener(Event.REMOVED_FROM_STAGE,this.removedFromStageHandler);
         if(stage && stage.hasEventListener(KeyboardEvent.KEY_DOWN))
         {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN,this.keyDownHandler);
            stage.removeEventListener(KeyboardEvent.KEY_UP,this.keyUpHandler);
         }
         if(this.configTimer)
         {
            this.configTimer.removeEventListener(TimerEvent.TIMER,this.loadConfig);
         }
         if(this.displayTimer)
         {
            this.displayTimer.removeEventListener(TimerEvent.TIMER,this.displayRadioWidget);
         }
         if(this.hudtools)
         {
            this.hudtools.Shutdown();
         }
      }
      
      public function initConfigTimer() : void
      {
         this.configTimer = new Timer(CONFIG_RELOAD_TIME);
         this.configTimer.addEventListener(TimerEvent.TIMER,this.loadConfig,false,0,true);
         this.configTimer.start();
      }
      
      public function onBuildMenu(parentItem:String = null) : *
      {
         try
         {
            if(parentItem == MOD_NAME)
            {
               if(config && config.disableRealTimeEdit)
               {
                  this.hudTools.AddMenuItem(HUDTOOLS_MENU_RELOAD_CONFIG,"Reload Config",true,false,250);
               }
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_PREV_RADIO,"Previous Radio",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_NEXT_RADIO,"Next Radio",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_PREV_SONG,"Previous Song",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_NEXT_SONG,"Next Song",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_PLAY_PAUSE,"Play/Stop",true,false,250);
               this.hudTools.AddMenuItem(HUDTOOLS_MENU_HIDE,"Force Hide",true,false,250);
            }
         }
         catch(e:Error)
         {
         }
      }
      
      public function onSelectMenu(selectItem:String) : *
      {
         try
         {
            if(selectItem == HUDTOOLS_MENU_PLAY_PAUSE)
            {
               config.Play = !config.Play;
               if(config.Play)
               {
                  startRadio();
               }
            }
            else if(selectItem == HUDTOOLS_MENU_NEXT_SONG)
            {
               ++skipSongs;
               queueNextSong();
            }
            else if(selectItem == HUDTOOLS_MENU_PREV_SONG)
            {
               --skipSongs;
               queueNextSong();
            }
            else if(selectItem == HUDTOOLS_MENU_NEXT_RADIO)
            {
               config.PlayRadioId++;
               if(config.PlayRadioId >= config.Radios.length)
               {
                  config.PlayRadioId = 0;
               }
            }
            else if(selectItem == HUDTOOLS_MENU_PREV_RADIO)
            {
               config.PlayRadioId--;
               if(config.PlayRadioId < 0)
               {
                  config.PlayRadioId = config.Radios.length - 1;
               }
            }
            else if(selectItem == HUDTOOLS_MENU_HIDE)
            {
               this.forceHide = !this.forceHide;
            }
            else if(selectItem == HUDTOOLS_MENU_RELOAD_CONFIG)
            {
               config.disableRealTimeEdit = false;
               this.loadConfig();
            }
         }
         catch(e:Error)
         {
         }
      }
      
      private function updateIsMainMenu(event:FromClientDataEvent) : void
      {
         var previouslyInMainMenu:Boolean;
         try
         {
            previouslyInMainMenu = this.isInMainMenu;
            this.isInMainMenu = Boolean(event) && Boolean(event.data) && Boolean(event.data.menuStackA) && Boolean(event.data.menuStackA.some(function(x:*):*
            {
               return x.menuName == MAIN_MENU;
            }));
            if(this.isInMainMenu && !previouslyInMainMenu)
            {
               this.isServerHop = true;
            }
         }
         catch(e:Error)
         {
         }
      }
      
      public function keyDownHandler(event:Event) : void
      {
         try
         {
            this.isKeyDownDetected[event.keyCode] = true;
            if(!config)
            {
               return;
            }
            if(config.debugKeys)
            {
               displayMessage("keyDown: " + event.keyCode + " - " + Buttons.getButtonKey(event.keyCode));
            }
            this.handleKey(event);
         }
         catch(e:Error)
         {
            displayMessage("Error keyDownHandler: " + e);
         }
      }
      
      public function keyUpHandler(event:Event) : void
      {
         try
         {
            if(!config)
            {
               return;
            }
            if(config.debugKeys)
            {
               displayMessage("keyUp (kd:" + Boolean(this.isKeyDownDetected[event.keyCode]) + "): " + event.keyCode + " - " + Buttons.getButtonKey(event.keyCode));
            }
            if(!this.isKeyDownDetected[event.keyCode])
            {
               this.handleKey(event);
            }
         }
         catch(e:Error)
         {
            displayMessage("Error keyUpHandler: " + e);
         }
      }
      
      private function handleKey(event:Event) : void
      {
         if(config.Hotkeys)
         {
            if(event.keyCode == config.Hotkeys.playStop)
            {
               config.Play = !config.Play;
               if(config.Play)
               {
                  startRadio();
               }
            }
            if(event.keyCode == config.Hotkeys.prevRadio)
            {
               config.PlayRadioId--;
               if(config.PlayRadioId < 0)
               {
                  config.PlayRadioId = config.Radios.length - 1;
               }
            }
            if(event.keyCode == config.Hotkeys.nextRadio)
            {
               config.PlayRadioId++;
               if(config.PlayRadioId >= config.Radios.length)
               {
                  config.PlayRadioId = 0;
               }
            }
            if(event.keyCode == config.Hotkeys.prevSong)
            {
               --skipSongs;
               queueNextSong();
            }
            if(event.keyCode == config.Hotkeys.nextSong)
            {
               ++skipSongs;
               queueNextSong();
            }
         }
      }
      
      private function radioButtonClickHandler(param1:MouseEvent) : *
      {
         var buttonId:Number = -1;
         buttonId = Number(this.radioButtons.indexOf(param1.target));
         if(buttonId != -1)
         {
            switch(buttonId)
            {
               case 0:
                  --skipSongs;
                  queueNextSong();
                  break;
               case 1:
                  config.Play = !config.Play;
                  startRadio();
                  break;
               case 2:
                  ++skipSongs;
                  queueNextSong();
                  break;
               case 3:
                  config.PlayRadioId--;
                  if(config.PlayRadioId < 0)
                  {
                     config.PlayRadioId = config.Radios.length - 1;
                  }
                  break;
               case 4:
                  config.PlayRadioId++;
                  if(config.PlayRadioId >= config.Radios.length)
                  {
                     config.PlayRadioId = 0;
                  }
            }
         }
      }
      
      public function queueNextSong() : void
      {
         if(skipSongs != 0)
         {
            if(currentRadio != null && currentRadio.playlist != null && currentRadio.playlist.length != 0)
            {
               if(currentRadio.order == "RANDOM")
               {
                  nextSongId = Math.floor(Math.random() * currentRadio.playlist.length);
               }
               else
               {
                  nextSongId = (nextSongId + skipSongs) % currentRadio.playlist.length;
                  if(nextSongId < 0)
                  {
                     nextSongId = currentRadio.playlist.length - 1;
                  }
               }
            }
            skipSongs = 0;
         }
      }
      
      public function loadConfig() : void
      {
         var loaderComplete:Function;
         var ioErrorHandler:Function;
         var url:URLRequest = null;
         var loader:URLLoader = null;
         try
         {
            if(config && Boolean(config.disableRealTimeEdit))
            {
               return;
            }
            loaderComplete = function(param1:Event):void
            {
               var jsonData:Object;
               try
               {
                  if(lastConfig != loader.data)
                  {
                     jsonData = new JSONDecoder(loader.data,true).getValue();
                     CustomRadiosConfig.init(jsonData);
                     initTextField();
                     initTimers();
                     lastConfig = loader.data;
                     if(config.Play)
                     {
                        startRadio();
                     }
                     displayRadioButtons();
                  }
               }
               catch(e:Error)
               {
                  ShowHUDMessage("Error parsing config (" + CustomRadiosConfig.ERROR_CODE + "): " + e);
               }
            };
            ioErrorHandler = function(param1:*):void
            {
               ShowHUDMessage("Error loading config: " + param1.text);
            };
            url = new URLRequest(CONFIG_FILE);
            loader = new URLLoader();
            loader.load(url);
            loader.addEventListener(Event.COMPLETE,loaderComplete,false,0,true);
            loader.addEventListener(IOErrorEvent.IO_ERROR,ioErrorHandler,false,0,true);
         }
         catch(e:Error)
         {
            ShowHUDMessage("Error loading config: " + e);
         }
      }
      
      private function displayRadioButtons() : *
      {
         var i:int = 0;
         var textfield:TextField = null;
         var textformat:TextFormat = null;
         try
         {
            if(radioButtons.length == 5)
            {
               this.refreshButtons = true;
               return;
            }
            i = 0;
            while(i < 5)
            {
               textfield = new TextField();
               textfield.addEventListener(MouseEvent.CLICK,radioButtonClickHandler,false,0,true);
               TextFieldEx.setTextAutoSize(textfield,TextFieldEx.TEXTAUTOSZ_FIT);
               addChild(textfield);
               textformat = new TextFormat(config.textFont,16,config.textColor);
               textformat.align = "center";
               textfield.background = true;
               textfield.border = true;
               textfield.selectable = false;
               textfield.defaultTextFormat = textformat;
               textfield.setTextFormat(textformat);
               textfield.visible = false;
               this.radioButtons.push(textfield);
               this.applyRadioButtonStyle(i);
               i++;
            }
         }
         catch(e:Error)
         {
            ShowHUDMessage("displayRadioButtons: " + e);
            displayMessage("displayRadioButtons: " + e);
         }
      }
      
      private function applyRadioButtonStyle(id:int) : void
      {
         if(id < 0 || id >= this.radioButtons.length)
         {
            return;
         }
         var textfield:TextField = this.radioButtons[id];
         GlobalFunc.SetText(textfield,config.ButtonNames[id].replace(STRING_HOTKEY,getRadioKey(id)),false);
         textfield.backgroundColor = config.backgroundColor;
         textfield.borderColor = config.textColor;
         textfield.textColor = config.textColor;
         if(id < 3)
         {
            var w:Number = config.Buttons.width / 3;
            textfield.width = w;
            textfield.height = config.Buttons.height / 2;
            textfield.x = config.Buttons.x + id * w;
            textfield.y = config.Buttons.y + textfield.height;
         }
         else
         {
            w = config.Buttons.width / 2;
            textfield.width = config.Buttons.width / 2;
            textfield.height = config.Buttons.height / 2;
            textfield.x = config.Buttons.x + (id - 3) * w;
            textfield.y = config.Buttons.y;
         }
      }
      
      private function getRadioKey(keyId:int) : String
      {
         return Buttons.getButtonKey(config.Hotkeys[buttonActions[keyId]]);
      }
      
      private function initTextField() : void
      {
         this.dummy_tf = new TextField();
         this.formatMessage();
      }
      
      private function initTimers() : void
      {
         if(this.displayTimer)
         {
            this.displayTimer.removeEventListener(TimerEvent.TIMER,this.displayRadioWidget);
         }
         this.displayTimer = new Timer(config.refresh);
         this.displayTimer.addEventListener(TimerEvent.TIMER,this.displayRadioWidget,false,0,true);
         this.displayTimer.start();
      }
      
      public function get isReloadable() : Boolean
      {
         return false;
      }
      
      public function get config() : Object
      {
         return CustomRadiosConfig.get();
      }
      
      public function get elapsedTime() : Number
      {
         return getTimer() / 1000;
      }
      
      public function formatMessage() : void
      {
         this.dummy_tf.text = MOD_VERSION;
         this.dummy_tf.x = config.x;
         this.dummy_tf.y = config.y;
         this.dummy_tf.width = config.width;
         this.dummy_tf.background = false;
         TextFieldEx.setTextAutoSize(this.dummy_tf,TextFieldEx.TEXTAUTOSZ_SHRINK);
         this.dummy_tf.autoSize = TextFieldAutoSize.LEFT;
         this.dummy_tf.wordWrap = false;
         this.dummy_tf.multiline = true;
         this.dummy_tf.visible = true;
         this.textFormat = new TextFormat(config.textFont,config.textSize,config.textColor);
         this.textFormat.align = config.textAlign;
         this.dummy_tf.defaultTextFormat = this.textFormat;
         this.dummy_tf.setTextFormat(this.textFormat);
         this.dummy_tf.filters = [new DropShadowFilter(2,45,0,1,1,1,1,BitmapFilterQuality.HIGH)];
         this.alpha = config.alpha;
         this.blendMode = config.blendMode;
      }
      
      public function resetMessages() : void
      {
         this.graphics.clear();
         this.textfield_index = 0;
         this.yOffset = 0;
         for(c in arrTextfields)
         {
            if(arrTextfields[c] != null)
            {
               arrTextfields[c].visible = false;
               arrTextfields[c].defaultTextFormat = this.textFormat;
               arrTextfields[c].setTextFormat(this.textFormat);
            }
         }
      }
      
      public function createTextfield() : TextField
      {
         tf = new TextField();
         tf.multiline = false;
         tf.wordWrap = false;
         tf.defaultTextFormat = this.textFormat;
         TextFieldEx.setTextAutoSize(tf,TextFieldEx.TEXTAUTOSZ_SHRINK);
         tf.setTextFormat(this.textFormat);
         addChild(tf);
         return tf;
      }
      
      public function applyConfig(tf:TextField) : void
      {
         tf.visible = true;
         tf.x = config.x;
         tf.background = false;
         tf.width = config.width;
         tf.height = this.dummy_tf.height;
         if(textfield_index == 0)
         {
            tf.y = config.y;
         }
         else
         {
            tf.y = LastDisplayTextfield.y + LastDisplayTextfield.height + config.ySpacing + yOffset;
            yOffset = 0;
         }
         tf.blendMode = config.textBlendMode;
         tf.filters = Boolean(config.textShadow) ? this.dummy_tf.filters : [];
      }
      
      public function displayMessage(text:String) : void
      {
         if(arrTextfields.length < textfield_index || arrTextfields[textfield_index] == null)
         {
            arrTextfields[textfield_index] = createTextfield();
         }
         applyConfig(arrTextfields[textfield_index]);
         arrTextfields[textfield_index].text = text;
         arrTextfields[textfield_index].height = dummy_tf.height * text.split("\n").length;
         ++textfield_index;
      }
      
      public function drawBackground() : void
      {
         if(config.background)
         {
            this.graphics.beginFill(config.backgroundColor,config.backgroundAlpha);
            this.graphics.drawRect(config.x,config.y,config.width,LastDisplayTextfield.y + LastDisplayTextfield.height - config.y);
            this.graphics.endFill();
         }
         if(config.anchor == "bottom")
         {
            this.y = -(LastDisplayTextfield.y + LastDisplayTextfield.height - config.y);
         }
         else if(this.y != 0)
         {
            this.y = 0;
         }
      }
      
      public function get LastDisplayTextfield() : TextField
      {
         if(textfield_index == 0)
         {
            return arrTextfields[textfield_index];
         }
         return arrTextfields[textfield_index - 1];
      }
      
      public function getCustomColor(name:String) : Number
      {
         if(config.customColors[name] != null)
         {
            return config.customColors[name];
         }
         return config.textColor;
      }
      
      public function applyColor(color:uint) : void
      {
         LastDisplayTextfield.textColor = color;
      }
      
      public function ProcessConsoleEvent(param1:String) : *
      {
         if(param1 == "/play")
         {
            if(config.Play)
            {
               return "Radio is already playing!";
            }
            config.Play = true;
            return "Radio started!";
         }
         if(param1 == "/stop")
         {
            if(!config.Play)
            {
               return "Radio is not playing!";
            }
            config.Play = false;
            return "Radio stopped!";
         }
      }
      
      public function startRadio() : void
      {
         if(!config || !config.Play || currentRadio != null)
         {
            return;
         }
         if(config.PlayRadioId >= 0 && config.PlayRadioId < config.Radios.length)
         {
            currentRadioId = config.PlayRadioId;
            currentRadio = config.Radios[currentRadioId];
            nextSong();
         }
      }
      
      public function nextSong() : void
      {
         if(!config || !config.Play)
         {
            currentRadio = null;
            currentSong = null;
            currentSongId = 0;
            nextSongId = -1;
            return;
         }
         if(!currentRadio || currentRadioId != config.PlayRadioId)
         {
            currentSong = null;
            currentSongId = 0;
            if(config.PlayRadioId >= 0 && config.PlayRadioId < config.Radios.length)
            {
               currentRadioId = config.PlayRadioId;
               currentRadio = config.Radios[currentRadioId];
            }
         }
         if(currentRadio.playlist.length == 0)
         {
            currentRadio = null;
            currentSong = null;
            currentSongId = 0;
            return;
         }
         if(!currentSong)
         {
            if(config.StartTrackId == "RANDOM")
            {
               currentSongId = Math.floor(Math.random() * currentRadio.playlist.length);
            }
            else if(config.StartTrackId >= 0 && config.StartTrackId < currentRadio.playlist.length)
            {
               currentSongId = config.StartTrackId;
            }
            else
            {
               currentSongId = 0;
            }
            if(currentRadio.order == "RANDOM")
            {
               nextSongId = Math.floor(Math.random() * currentRadio.playlist.length);
               while(currentSongId == nextSongId)
               {
                  nextSongId = Math.floor(Math.random() * currentRadio.playlist.length);
               }
            }
            else
            {
               nextSongId = (currentSongId + 1) % currentRadio.playlist.length;
            }
         }
         else if(currentRadio.order == "RANDOM")
         {
            var prevSongId:int = currentSongId;
            if(nextSongId == -1)
            {
               currentSongId = Math.floor(Math.random() * currentRadio.playlist.length);
            }
            else
            {
               currentSongId = nextSongId;
            }
            nextSongId = Math.floor(Math.random() * currentRadio.playlist.length);
            while(currentSongId == nextSongId)
            {
               nextSongId = Math.floor(Math.random() * currentRadio.playlist.length);
            }
         }
         else
         {
            if(nextSongId == -1)
            {
               currentSongId = (currentSongId + 1) % currentRadio.playlist.length;
            }
            else
            {
               currentSongId = nextSongId % currentRadio.playlist.length;
            }
            nextSongId = (currentSongId + 1) % currentRadio.playlist.length;
         }
         currentSong = currentRadio.playlist[currentSongId];
         GlobalFunc.PlayMenuSound(currentSong.id);
         currentSongPlayTimestamp = this.elapsedTime;
         nextSongUID = setTimeout(nextSong,1000 * currentSong.duration);
      }
      
      public function displayRadioWidget() : void
      {
         var t1:Number;
         var vis:Boolean;
         var i:int;
         var parts:Array;
         var isValidHM:Boolean;
         try
         {
            t1 = Number(getTimer());
            if(this.isServerHop)
            {
               clearTimeout(nextSongUID);
               nextSongUID = setTimeout(nextSong,1000);
               this.isServerHop = false;
            }
            isValidHM = !this.forceHide && this.isValidHUDMode();
            if(!this.isHudMenu && this.topLevel != null && this.topLevel.SocialMenu_mc != null)
            {
               vis = Boolean(this.topLevel.SocialMenu_mc.show);
               i = 0;
               if(refreshButtons)
               {
                  while(i < this.radioButtons.length)
                  {
                     this.radioButtons[i].visible = vis;
                     applyRadioButtonStyle(i);
                     i++;
                  }
                  refreshButtons = false;
               }
               else
               {
                  while(i < this.radioButtons.length)
                  {
                     this.radioButtons[i].visible = vis;
                     i++;
                  }
               }
            }
            this.resetMessages();
            if(!isValidHM)
            {
               return;
            }
            if(config.debug)
            {
               displayMessage(FULL_MOD_NAME);
               applyColor(config.textColorError);
               displayMessage("HUDMode: " + (this.isInMainMenu ? MAIN_MENU : this.HUDModeData.data.hudMode) + " " + (isHudMenu ? "(HUD)" : "(Overlay)"));
               applyColor(config.textColorError);
               displayMessage("RenderTime: " + this.lastRenderTime + "ms");
               applyColor(config.textColorError);
               displayMessage("topLevel: " + this.topLevel);
               if(this.topLevel)
               {
                  displayMessage("SocialMenu_mc: " + this.topLevel.SocialMenu_mc);
                  if(this.topLevel.SocialMenu_mc)
                  {
                     displayMessage("show: " + this.topLevel.SocialMenu_mc.show);
                  }
               }
               displayMessage("radioButtons: " + this.radioButtons.length);
            }
            if(currentRadio && currentSong)
            {
               parts = config.Format.replace(STRING_RADIO_NAME,currentRadio.name).replace(STRING_NUMBER_OF_TRACKS,currentRadio.playlist.length).replace(STRING_TRACK_ID,currentSongId + 1).replace(STRING_TRACK_NAME,currentSong.name).replace(STRING_NEXT_TRACK_NAME,nextSongId >= 0 && nextSongId < currentRadio.playlist.length ? currentRadio.playlist[nextSongId].name : "...").replace(STRING_TRACK_DURATION,GlobalFunc.FormatTimeString(currentSong.duration)).replace(STRING_ELAPSED_DURATION,GlobalFunc.FormatTimeString(this.elapsedTime - currentSongPlayTimestamp) || "0:00").split("\n");
               i = 0;
               while(i < parts.length)
               {
                  displayMessage(parts[i]);
                  i++;
               }
            }
            if(!config.Play)
            {
               if(currentSong)
               {
                  displayMessage(config.FormatRadioTurningOff);
                  applyColor(config.textColorError);
               }
               else
               {
                  displayMessage(config.FormatRadioOff);
                  applyColor(config.textColorError);
               }
            }
            else if(config.PlayRadioId < 0 || config.PlayRadioId >= config.Radios.length)
            {
               displayMessage(config.FormatRadioNotExist);
               applyColor(config.textColorError);
            }
            else if(config.Radios[config.PlayRadioId].playlist.length == 0)
            {
               displayMessage(config.FormatRadioNoPlaylist);
               applyColor(config.textColorError);
            }
            else if(currentRadioId != config.PlayRadioId)
            {
               displayMessage(config.FormatRadioSwitching.replace(STRING_NEXT_RADIO_NAME,config.Radios[config.PlayRadioId].name));
               applyColor(config.textColorError);
            }
            drawBackground();
            this.lastRenderTime = getTimer() - t1;
         }
         catch(error:*)
         {
            displayMessage("Error displaying: " + error);
            drawBackground();
         }
      }
      
      public function isValidHUDMode() : Boolean
      {
         if(config)
         {
            if(config.HUDModesState == CustomRadiosConfig.STATE_HIDDEN)
            {
               return this.isInMainMenu ? config.HUDModes.indexOf(MAIN_MENU) == -1 : config.HUDModes.indexOf(this.HUDModeData.data.hudMode) == -1;
            }
            return this.isInMainMenu ? config.HUDModes.indexOf(MAIN_MENU) != -1 : config.HUDModes.indexOf(this.HUDModeData.data.hudMode) != -1;
         }
         return true;
      }
   }
}

