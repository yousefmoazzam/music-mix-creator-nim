import std/os
from std/strutils import join

import unittest2

from ../src/lib import
  generateSongConversionCommand, generateInputFilesFlags,
  generateConvertedOutputFilepaths, generateConcatArgsFileOrdering,
  generateConcateArgsTrims, generateConcatArgsFinalPart, generateConcatArgs

suite "test suite":
  test "test generateSongConversionCommand":
    let songFileName = "SongA.mp3"
    let songPath = joinPath("/home/test-mix/", songFileName)
    let outputDirPath = "/home/outdir"
    let convertedOutDir = "converted-audio-files"
    let convertedOutFilePath = joinPath(outputDirPath, convertedOutDir, songFileName)
    let expectedProgram = "/usr/bin/ffmpeg"
    var expectedArgs = @["-i", "-vn", "-ar", "44100", "-ac", "2", "-b:a", "192k"]
    expectedArgs.add(convertedOutFilePath)
    let (program, args) = generateSongConversionCommand(songPath, outputDirPath)
    doAssert program == expectedProgram
    doAssert args == expectedArgs

  test "test generateInputFilesFlags":
    let songPaths = [
      "/home/converted-audio-files/SongA.mp3", "/home/converted-audio-files/SongB.mp3",
      "/home/converted-audio-files/SongC.mp3",
    ]
    let flagsAndPaths = generateInputFilesFlags(songPaths[0 .. songPaths.len() - 1])
    let expectedFlagsAndPaths = [
      "-i",
      songPaths[0],
      "-i",
      songPaths[1],
      "-i",
      songPaths[2],
      "-f",
      "lavfi",
      "-i",
      "anullsrc",
    ]
    doAssert expectedFlagsAndPaths == flagsAndPaths[0 .. flagsAndPaths.len() - 1]

  test "test generateConvertedOutputFilepaths":
    let inputSongPaths = [
      "/home/test-mix/SongA.mp3", "/home/test-mix/SongB.mp3", "/home/test-mix/SongC.mp3"
    ]
    let outDirPath = "/home/mix-out"
    let expectedConvertedSongPaths = [
      joinPath(outDirPath, extractFilename(inputSongPaths[0])),
      joinPath(outDirPath, extractFilename(inputSongPaths[1])),
      joinPath(outDirPath, extractFilename(inputSongPaths[2])),
    ]
    let convertedSongPaths = generateConvertedOutputFilepaths(
      inputSongPaths[0 .. inputSongPaths.len() - 1], outDirPath
    )
    doAssert expectedConvertedSongPaths ==
      convertedSongPaths[0 .. convertedSongPaths.len() - 1]

  test "test generateConcatArgsFileOrdering":
    let noOfSongFiles = 2
    let expectedOutput = "[0][g0][1]"
    let output = generateConcatArgsFileOrdering(noOfSongFiles)
    doAssert output == expectedOutput

  test "test generateConcatArgsTrims":
    let noOfSongFiles = 3
    let expectedOutput = "[3]atrim=duration=1[g0];[3]atrim=duration=1[g1];"
    let output = generateConcateArgsTrims(noOfSongFiles)
    doAssert output == expectedOutput

  test "test generateConcatArgsFinalPart":
    let noOfSongFiles = 3
    let expectedOutput = "concat=n=5:v=0:a=1"
    let output = generateConcatArgsFinalPart(noOfSongFiles)
    doAssert output == expectedOutput

  test "test generateConcatArgs":
    let noOfSongFiles = 4
    let expectedTrimsValues =
      ["[4]atrim=duration=1[g0]", "[4]atrim=duration=1[g1]", "[4]atrim=duration=1[g2]"]
    var expectedTrimsPart = join(expectedTrimsValues, ";")
    expectedTrimsPart.add(";")
    let expectedOrderingPart = "[0][g0][1][g1][2][g2][3]"
    let expectedConcatPart = "concat=n=7:v=0:a=1"
    let expectedConcatArgs =
      join([expectedTrimsPart, expectedOrderingPart, expectedConcatPart])
    let concatArgs = generateConcatArgs(noOfSongFiles)
    doAssert concatArgs == expectedConcatArgs
