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
      
      public static const MOD_VERSION:String = "1.0.1";
      
      public static const FULL_MOD_NAME:String = MOD_NAME + " " + MOD_VERSION;
      
      public static const CONFIG_FILE:String = "../CustomRadios.json";
      
      public static const CONFIG_RELOAD_TIME:uint = 10200;
      
      private static const STRING_NUMBER_OF_TRACKS:String = "{numberOfTracks}";
      
      private static const STRING_RADIO_NAME:String = "{radioName}";
      
      private static const STRING_TRACK_ID:String = "{trackId}";
      
      private static const STRING_TRACK_NAME:String = "{trackName}";
      
      private static const STRING_TRACK_DURATION:String = "{trackDuration}";
      
      private static const STRING_ELAPSED_DURATION:String = "{elapsedDuration}";
      
      private static const TITLE_HUDMENU:String = "HUDMenu";
       
      
      private var lastRenderTime:Number = 0;
      
      private var topLevel:* = null;
      
      private var dummy_tf:TextField;
      
      private var textFormat:TextFormat;
      
      private var timer:Timer;
      
      private var configTimer:Timer;
      
      private var displayTimer:Timer;
      
      private var lastConfig:String;
      
      private var HUDModeData:*;
      
      private var arrTextfields:Array;
      
      private var textfield_index:int = 0;
      
      private var yOffset:Number = 0;
      
      private var currentRadio:*;
      
      private var currentSong:*;
      
      private var currentSongPlayTimestamp:Number = 0;
      
      private var currentSongId:int = 0;
      
      private var currentRadioId:int = 0;
      
      public function CustomRadios()
      {
         arrTextfields = [];
         super();
         addEventListener(Event.ADDED_TO_STAGE,this.addedToStageHandler);
         this.HUDModeData = BSUIDataManager.GetDataFromClient("HUDModeData");
         this.configTimer = new Timer(CONFIG_RELOAD_TIME);
         this.configTimer.addEventListener(TimerEvent.TIMER,this.loadConfig);
         this.configTimer.start();
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
         var movieRoot:* = stage.getChildAt(0);
         if(Boolean(movieRoot) && getQualifiedClassName(movieRoot) == TITLE_HUDMENU)
         {
            this.topLevel = movieRoot;
            trace(MOD_NAME + " added to stage: " + getQualifiedClassName(movieRoot));
         }
         else
         {
            trace(MOD_NAME + " not added to stage: " + getQualifiedClassName(movieRoot));
            ShowHUDMessage("Not added to stage: " + getQualifiedClassName(movieRoot));
         }
      }
      
      public function loadConfig() : void
      {
         var loaderComplete:Function;
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
                  }
               }
               catch(e:Error)
               {
                  ShowHUDMessage("Error loading config: " + e);
               }
            };
            url = new URLRequest(CONFIG_FILE);
            loader = new URLLoader();
            loader.load(url);
            loader.addEventListener(Event.COMPLETE,loaderComplete);
         }
         catch(e:Error)
         {
            ShowHUDMessage("Error loading config: " + e);
         }
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
         this.displayTimer.addEventListener(TimerEvent.TIMER,this.displayRadioWidget);
         this.displayTimer.start();
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
         textfield_index++;
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
         if(!config.Play || currentRadio != null)
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
         if(!config.Play)
         {
            currentRadio = null;
            currentSong = null;
            currentSongId = 0;
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
         }
         else if(currentRadio.order == "RANDOM")
         {
            var prevSongId:int = currentSongId;
            currentSongId = Math.floor(Math.random() * currentRadio.playlist.length);
            if(currentSongId == prevSongId)
            {
               currentSongId = Math.floor(Math.random() * currentRadio.playlist.length);
            }
         }
         else
         {
            currentSongId = (currentSongId + 1) % currentRadio.playlist.length;
         }
         currentSong = currentRadio.playlist[currentSongId];
         GlobalFunc.PlayMenuSound(currentSong.id);
         currentSongPlayTimestamp = this.elapsedTime;
         setTimeout(nextSong,1000 * currentSong.duration);
      }
      
      public function displayRadioWidget() : void
      {
         var t1:Number;
         try
         {
            t1 = Number(getTimer());
            this.visible = this.isValidHUDMode();
            if(!this.visible)
            {
               return;
            }
            this.resetMessages();
            if(config.debug)
            {
               displayMessage(FULL_MOD_NAME);
               applyColor(config.textColorError);
               displayMessage("HUDMode: " + this.HUDModeData.data.hudMode);
               applyColor(config.textColorError);
               displayMessage("RenderTime: " + this.lastRenderTime + "ms");
               applyColor(config.textColorError);
            }
            if(currentRadio && currentSong)
            {
               displayMessage(config.Format.replace(STRING_RADIO_NAME,currentRadio.name).replace(STRING_NUMBER_OF_TRACKS,currentRadio.playlist.length).replace(STRING_TRACK_ID,currentSongId + 1).replace(STRING_TRACK_NAME,currentSong.name).replace(STRING_TRACK_DURATION,GlobalFunc.FormatTimeString(currentSong.duration)).replace(STRING_ELAPSED_DURATION,GlobalFunc.FormatTimeString(this.elapsedTime - currentSongPlayTimestamp) || "0:00"));
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
               displayMessage(config.FormatRadioSwitching);
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
               return config.HUDModes.indexOf(this.HUDModeData.data.hudMode) == -1;
            }
            return config.HUDModes.indexOf(this.HUDModeData.data.hudMode) != -1;
         }
         return true;
      }
   }
}
