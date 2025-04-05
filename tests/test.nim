import std/os

import unittest2

import ../src/lib

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
