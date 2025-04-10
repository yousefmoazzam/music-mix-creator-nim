from std/os import joinPath, splitPath, extractFilename
from std/strformat import fmt
from std/strutils import join, parseFloat, split

const FFMPEG_PATH = "/usr/bin/ffmpeg"
const FFPROBE_PATH = "/usr/bin/ffprobe"
const CONVERTED_OUT_DIR = "converted-audio-files"
const INPUT_FLAG = "-i"
const SONG_CONVERSION_FLAGS = ["-vn", "-ar", "44100", "-ac", "2", "-b:a", "192k"]
const SILENCE_INPUT = ["-f", "lavfi", "-i", "anullsrc"]

export FFMPEG_PATH

func generateSongConversionCommand*(
    songPath: string, outPath: string
): (string, seq[string]) =
  let (_, fileName) = splitPath(songPath)
  let outputFilePath = joinPath(outPath, CONVERTED_OUT_DIR, fileName)
  var args = @[INPUT_FLAG] & @SONG_CONVERSION_FLAGS & @[outputFilePath]
  (FFMPEG_PATH, args)

func generateInputFilesFlags*(paths: seq[string]): seq[string] =
  var args: seq[string] = @[]
  for song in paths:
    args.add("-i")
    args.add(song)
  for arg in SILENCE_INPUT:
    args.add(arg)
  args

func generateConvertedOutputFilepaths*(
    paths: seq[string], outDirPath: string
): seq[string] =
  var convertedPaths: seq[string] = @[]
  for path in paths:
    let fileName = extractFilename(path)
    convertedPaths.add(joinPath(outDirPath, fileName))
  convertedPaths

func generateConcatArgsFileOrdering*(noOfFiles: int): string =
  var res = ""
  for i in 0 .. noOfFiles - 2:
    let songSilencePair = fmt("[{i}][g{i}]")
    res.add(songSilencePair)
  let finalSongNoSilence = fmt("[{noOfFiles - 1}]")
  res.add(finalSongNoSilence)
  res

func generateConcateArgsTrims*(noOfFiles: int): string =
  var vals: seq[string] = @[]
  for i in 0 .. noOfFiles - 2:
    let silenceTrim = fmt("[{noOfFiles}]atrim=duration=1[g{i}]")
    vals.add(silenceTrim)
  var res = join(vals, ";")
  res.add(";")
  res

func generateConcatArgsFinalPart*(noOfFiles: int): string =
  let noOfSilences = noOfFiles - 1
  let noOfAudioPieces = noOfFiles + noOfSilences
  fmt("concat=n={noOfAudioPieces}:v=0:a=1")

func generateConcatArgs*(noOfFiles: int): string =
  let trimsPart = generateConcateArgsTrims(noOfFiles)
  let orderingPart = generateConcatArgsFileOrdering(noOfFiles)
  let concatPart = generateConcatArgsFinalPart(noOfFiles)
  join([trimsPart, orderingPart, concatPart])

func generateFfprobeCommand*(mixFilePath: string): (string, array[7, string]) =
  let args =
    ["-show_entries", "format=duration", "-v", "quiet", "-of", "csv", mixFilePath]
  (FFPROBE_PATH, args)

func parseFfprobeOutput*(s: string): float64 =
  let vals = s.split(',')
  parseFloat(vals[1])

func generateAudioVideoMuxCommand*(
    imagePath: string, audioPath: string, duration: float64, outPath: string
): (string, array[20, string]) =
  let args = [
    "-loop",
    "1",
    "-framerate",
    "24",
    "-i",
    imagePath,
    "-i",
    audioPath,
    "-vf",
    "fade=t=in:st=0:d=10,",
    fmt("fade=t=out:st={duration - 10}:d=10"),
    "-max_muxing_queue_size",
    "1024",
    "-c:v",
    "libx264",
    "-tune",
    "stillimage",
    "-t",
    fmt("{duration}"),
    outPath,
  ]
  (FFMPEG_PATH, args)
