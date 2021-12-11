//
//  Configuration.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AVFoundation
import VideoToolbox

let outputContentType = AVFileType.mp4
let outputFileTypeProfile = AVFileTypeProfile.mpeg4AppleHLS
let segmentDuration = 6
let segmentTimescale = CMTimeScale(6000)
let segmentFileNamePrefix = "fileSequence"
let indexFileName = "prog_index.m3u8"

let sessionPreset: AVCaptureSession.Preset = .hd1280x720

/*
    Apple HLS fMP4 does not have an Edit List Box ('elst') in an initialization segment to remove
    audio priming duration which advanced audio formats like AAC have, since the sample tables
    are empty.  As a result, if the output PTS of the first non-fully trimmed audio sample buffer is
    kCMTimeZero, the audio samples’ presentation time in segment files may be pushed forward by the
    audio priming duration.  This may cause audio and video to be out of sync.  You should add a time
    offset to all samples to avoid this situation.
*/
let startTimeOffset = CMTime.zero

let audioCompressionSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    // For simplicity, hard-code a common sample rate.
    // For a production use case, modify this as necessary to get the desired results given the source content.
    AVSampleRateKey: 44_100,
    AVNumberOfChannelsKey: 2,
    AVEncoderBitRateKey: 160_000
]

let videoCompressionSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    // For simplicity, assume 16:9 aspect ratio.
    // For a production use case, modify this as necessary to match the source content.
    AVVideoWidthKey: 1152,
    AVVideoHeightKey: 720,
]
