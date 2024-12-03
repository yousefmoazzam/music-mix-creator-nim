import std/os
import std/private/ospaths2

const FFMPEG_PATH = "/usr/bin/ffmpeg"
const CONVERTED_OUT_DIR = "converted-audio-files"
const INPUT_FLAG = "-i"
const SONG_CONVERSION_FLAGS = ["-vn", "-ar", "44100", "-ac", "2", "-b:a", "192k"]

func generateSongConversionCommand*(
  songPath: string,
  outPath: string
): (string, seq[string]) =
  let (_, fileName) = splitPath(songPath)
  let outputFilePath = joinPath(outPath, CONVERTED_OUT_DIR, fileName)
  var args = @[INPUT_FLAG] & @SONG_CONVERSION_FLAGS & @[outputFilePath]
  return (FFMPEG_PATH, args)
