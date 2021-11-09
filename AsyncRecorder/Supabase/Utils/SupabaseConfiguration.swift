//
//  Configuration.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 07/11/2021.
//

import Foundation

let videoBucket = "videos"
let thumbnailBucket = "thumbnails"
let listVideoBucket = "list/videos"

let temporaryDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(),
                                            isDirectory: true)

let deleteDelay = 5.0
