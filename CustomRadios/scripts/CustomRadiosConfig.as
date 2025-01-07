package
{
   import utils.Parser;
   
   public class CustomRadiosConfig
   {
      
      public static const STATE_HIDDEN:String = "hidden";
      
      public static const STATE_SHOWN:String = "shown";
      
      private static var _config:Object;
       
      
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
         var config:* = jsonObject;
         config.x = Parser.parseNumber(config.x,0);
         config.y = Parser.parseNumber(config.y,0);
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
         config.Format = Boolean(config.Format) ? config.Format : "{radioName} [{trackId}/{numberOfTracks}]\n{trackName}\n{elapsedDuration}/{trackDuration}";
         config.FormatRadioOff = Boolean(config.FormatRadioOff) ? config.FormatRadioOff : "Radio off!";
         config.FormatRadioTurningOff = Boolean(config.FormatRadioTurningOff) ? config.FormatRadioTurningOff : "Radio turning off...";
         config.FormatRadioSwitching = Boolean(config.FormatRadioSwitching) ? config.FormatRadioSwitching : "Switching radio station...";
         config.FormatRadioNoPlaylist = Boolean(config.FormatRadioNoPlaylist) ? config.FormatRadioNoPlaylist : "Selected Radio has no tracks listed!";
         config.FormatRadioNotExist = Boolean(config.FormatRadioNotExist) ? config.FormatRadioNotExist : "Selected RadioId doesn\'t exist!";
         config.HUDModesState = getState(config.HUDModesState);
         if(!config.HUDModes)
         {
            config.HUDModes = [];
         }
         if(!config.Radios)
         {
            config.Radios = [];
         }
         else
         {
            for(radio in config.Radios)
            {
               config.Radios[radio].name = Boolean(config.Radios[radio].name) ? config.Radios[radio].name : "Untitled Radio";
               config.Radios[radio].order = Boolean(config.Radios[radio].order) ? config.Radios[radio].order : "ORDERED";
               config.Radios[radio].playlist = Boolean(config.Radios[radio].playlist) ? config.Radios[radio].playlist : [];
            }
         }
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
