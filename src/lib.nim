import std/os
import std/strformat
from std/strutils import join

const FFMPEG_PATH = "/usr/bin/ffmpeg"
const CONVERTED_OUT_DIR = "converted-audio-files"
const INPUT_FLAG = "-i"
const SONG_CONVERSION_FLAGS = ["-vn", "-ar", "44100", "-ac", "2", "-b:a", "192k"]
const SILENCE_INPUT = ["-f", "lavfi", "-i", "anullsrc"]

func generateSongConversionCommand*(
    songPath: string, outPath: string
): (string, seq[string]) =
  let (_, fileName) = splitPath(songPath)
  let outputFilePath = joinPath(outPath, CONVERTED_OUT_DIR, fileName)
  var args = @[INPUT_FLAG] & @SONG_CONVERSION_FLAGS & @[outputFilePath]
  return (FFMPEG_PATH, args)

func generateInputFilesFlags*(paths: seq[string]): seq[string] =
  var args: seq[string] = @[]
  for song in paths:
    args.add("-i")
    args.add(song)
  for arg in SILENCE_INPUT:
    args.add(arg)
  return args

func generateConvertedOutputFilepaths*(
    paths: seq[string], outDirPath: string
): seq[string] =
  var convertedPaths: seq[string] = @[]
  for path in paths:
    let fileName = extractFilename(path)
    convertedPaths.add(joinPath(outDirPath, fileName))
  return convertedPaths

func generateConcatArgsFileOrdering*(noOfFiles: int): string =
  var res = ""
  for i in 0 .. noOfFiles - 2:
    let songSilencePair = fmt("[{i}][g{i}]")
    res.add(songSilencePair)
  let finalSongNoSilence = fmt("[{noOfFiles - 1}]")
  res.add(finalSongNoSilence)
  return res

func generateConcateArgsTrims*(noOfFiles: int): string =
  var vals: seq[string] = @[]
  for i in 0 .. noOfFiles - 2:
    let silenceTrim = fmt("[{noOfFiles}]atrim=duration=1[g{i}]")
    vals.add(silenceTrim)
  var res = join(vals, ";")
  res.add(";")
  return res

func generateConcatArgsFinalPart*(noOfFiles: int): string =
  let noOfSilences = noOfFiles - 1
  let noOfAudioPieces = noOfFiles + noOfSilences
  return fmt("concat=n={noOfAudioPieces}:v=0:a=1")
