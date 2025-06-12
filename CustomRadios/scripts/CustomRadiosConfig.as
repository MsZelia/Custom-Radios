package
{
   import utils.Parser;
   
   public class CustomRadiosConfig
   {
      
      public static const STATE_HIDDEN:String = "hidden";
      
      public static const STATE_SHOWN:String = "shown";
      
      public static const BUTTON_ACTIONS:Array = ["prevSong","playStop","nextSong","prevRadio","nextRadio"];
      
      private static var _config:Object;
      
      public static var ERROR_CODE:String = "";
       
      
      public function CustomRadiosConfig()
      {
         super();
      }
      
      public static function get() : Object
      {
         return _config;
      }
      
      public static function init(jsonObject:*) : Object
      {
         ERROR_CODE = "init";
         var config:* = jsonObject;
         ERROR_CODE = "WingetSettings";
         config.x = Parser.parseNumber(config.x,0);
         config.y = Parser.parseNumber(config.y,5);
         config.anchor = Boolean(config.anchor) ? config.anchor.toLowerCase() : "top";
         config.ySpacing = Parser.parseNumber(config.ySpacing,0);
         config.width = Parser.parseNumber(config.width,400);
         config.textSize = Parser.parseNumber(config.textSize,18);
         config.textFont = Boolean(config.textFont) ? config.textFont : "$MAIN_Font";
         config.textAlign = Boolean(config.textAlign) ? config.textAlign.toLowerCase() : "left";
         config.textColor = Parser.parseNumber(config.textColor,16777215);
         config.textColorError = Parser.parseNumber(config.textColorError,16711680);
         config.textShadow = Parser.parseBoolean(config.textShadow,true);
         config.background = Parser.parseBoolean(config.background,false);
         config.backgroundColor = Parser.parseNumber(config.backgroundColor,2236962);
         config.alpha = Parser.parseNumber(config.alpha,1);
         config.backgroundAlpha = Parser.parseNumber(config.backgroundAlpha,0.25);
         config.blendMode = Boolean(config.blendMode) ? config.blendMode.toLowerCase() : "normal";
         config.textBlendMode = Boolean(config.textBlendMode) ? config.textBlendMode.toLowerCase() : "normal";
         config.refresh = Parser.parseNumber(config.refresh,1000);
         config.Play = Parser.parseBoolean(config.Play,false);
         config.PlayRadioId = Parser.parseNumber(config.PlayRadioId,0);
         config.StartTrackId = config.StartTrackId != null ? (config.StartTrackId is String && config.StartTrackId == "RANDOM" ? config.StartTrackId : Parser.parseNumber(config.StartTrackId,0)) : 0;
         ERROR_CODE = "Formats";
         config.Format = Boolean(config.Format) ? config.Format : "{radioName} [{trackId}/{numberOfTracks}]\n{trackName}\n{elapsedDuration}/{trackDuration}\n\nNext up: {nextTrackName}";
         config.FormatRadioOff = Boolean(config.FormatRadioOff) ? config.FormatRadioOff : "Radio off!";
         config.FormatRadioTurningOff = Boolean(config.FormatRadioTurningOff) ? config.FormatRadioTurningOff : "Radio turning off...";
         config.FormatRadioSwitching = Boolean(config.FormatRadioSwitching) ? config.FormatRadioSwitching : "Switching to... {nextRadioName}";
         config.FormatRadioNoPlaylist = Boolean(config.FormatRadioNoPlaylist) ? config.FormatRadioNoPlaylist : "Selected Radio has no tracks!";
         config.FormatRadioNotExist = Boolean(config.FormatRadioNotExist) ? config.FormatRadioNotExist : "Selected RadioId doesn\'t exist!";
         ERROR_CODE = "Buttons";
         if(!config.Buttons)
         {
            config.Buttons = {
               "x":0,
               "y":160,
               "width":390,
               "height":60
            };
         }
         else
         {
            config.Buttons.x = Parser.parseNumber(config.Buttons.x,0);
            config.Buttons.y = Parser.parseNumber(config.Buttons.y,160);
            config.Buttons.width = Parser.parseNumber(config.Buttons.width,390);
            config.Buttons.height = Parser.parseNumber(config.Buttons.height,60);
         }
         ERROR_CODE = "ButtonNames";
         if(!config.ButtonNames || !(config.ButtonNames is Array) || config.ButtonNames.length != 5)
         {
            config.ButtonNames = ["{hotkey}) Prev Song","{hotkey}) Play/Stop","Next Song ({hotkey}","{hotkey}) Prev Radio   <<",">>   Next Radio ({hotkey}"];
         }
         ERROR_CODE = "Hotkeys";
         if(!config.Hotkeys)
         {
            config.Hotkeys = {
               "prevRadio":112,
               "nextRadio":113,
               "prevSong":114,
               "nextSong":115,
               "playStop":116
            };
         }
         else
         {
            var action:String = null;
            for each(action in BUTTON_ACTIONS)
            {
               config.Hotkeys[action] = Parser.parsePositiveNumber(config.Hotkeys[action],0);
            }
         }
         ERROR_CODE = "HUDModesState";
         config.HUDModesState = getState(config.HUDModesState);
         if(!config.HUDModes)
         {
            config.HUDModes = [];
         }
         ERROR_CODE = "Radios";
         if(!config.Radios)
         {
            config.Radios = [];
         }
         else
         {
            for(radio in config.Radios)
            {
               ERROR_CODE = "Radio_" + radio;
               config.Radios[radio].name = Boolean(config.Radios[radio].name) ? config.Radios[radio].name : "Untitled Radio";
               config.Radios[radio].order = Boolean(config.Radios[radio].order) ? config.Radios[radio].order : "ORDERED";
               config.Radios[radio].playlist = Boolean(config.Radios[radio].playlist) ? config.Radios[radio].playlist : [];
            }
         }
         ERROR_CODE = "noError";
         _config = config;
         return _config;
      }
      
      private static function getState(data:Object) : String
      {
         if(!data)
         {
            return STATE_HIDDEN;
         }
         if(data.toLowerCase() == STATE_SHOWN)
         {
            return STATE_SHOWN;
         }
         return STATE_HIDDEN;
      }
   }
}
