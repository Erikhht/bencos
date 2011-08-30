{******************************************************
 * uConfig - Encoding Job Params
 * part of BENCOS
 ******************************************************}
unit uconfig;

{$mode objfpc}

interface

uses
  Classes, SysUtils;

type
  TConfig = record
    { Base }
    sSource: string;
    sOutputPath: string;
    sTemp: string;
    iContainer: integer;         // 0: mp4, 1: mkv, 2: wemb

    { Video }
    TVideo: record
      iCodec: integer;           // 0: h264, 1: vp8
      iCodecMode: integer;       // 0: bitrate, 1: filesize, 2: CRF
      iBitrate: integer;         // kbps
      iFileSize: integer;        // MB
      fQuality: double;          // 0 - 51 (quant)
      sPreset: string;
      sProfile: string;
      sTune: string;
      iNbPass: integer;
    end;

    { Audio }
    TAudio: record
      iCodec: integer;           // 0: AAC HE+PS, 1: AAC HE, 2: AAC LC, 3: Vorbis
      iBitrate: integer;         // kbps / quality
      iLanguage: integer;        // 0: default, 1: Japanese, 2: English, 3: French, 4: Spanish
    end;

    { Subtitle }
    TSubtitle: record
      iLanguage: integer;        // 0: default, 1: Japanese, 2: English, 3: French, 4: Spanish
    end;
  end;

implementation

end.

