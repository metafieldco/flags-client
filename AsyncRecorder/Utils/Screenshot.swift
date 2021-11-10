//
//  Screenshot.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 09/11/2021.
//

import Foundation

var screenshotImage: CGImage?
let screenshotFileName = "thumb.png"

class Screenshot {
    func capture(){// take screenshot
        let displayID = CGMainDisplayID()
        if let img = CGDisplayCreateImage(displayID){
            screenshotImage = resizeScreenshot(img)
            saveScreenshot(screenshotImage)
        }
    }

    private func saveScreenshot(_ screenshot: CGImage?){
        guard let screenshot = screenshot else {
            print("Failed to save screenshot to tmp file. Screenshot doesn't exist.")
            return
        }

        let temporaryDirectoryUrl = URL(fileURLWithPath: NSTemporaryDirectory(),
                                                    isDirectory: true)
        if let destination = CGImageDestinationCreateWithURL(temporaryDirectoryUrl.appendingPathComponent(screenshotFileName) as CFURL, kUTTypePNG, 1, nil) {
            CGImageDestinationAddImage(destination, screenshot, nil)
            if CGImageDestinationFinalize(destination) {
                print("Saved screenshot to tmp file")
            }else{
                print("Failed to save screenshot to tmp file")
            }
        }
    }

    private func resizeScreenshot(_ image: CGImage) -> CGImage? {
        var ratio: Float = 0.0
        let imageWidth = Float(image.width)
        let imageHeight = Float(image.height)
        let maxWidth: Float = 1024.0
        let maxHeight: Float = 768.0
        
        // Get ratio (landscape or portrait)
        if (imageWidth > imageHeight) {
            ratio = maxWidth / imageWidth
        } else {
            ratio = maxHeight / imageHeight
        }
        
        // Calculate new size based on the ratio
        if ratio > 1 {
            ratio = 1
        }
        
        let width = imageWidth * ratio
        let height = imageHeight * ratio
        
        guard let colorSpace = image.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.bytesPerRow, space: colorSpace, bitmapInfo: image.alphaInfo.rawValue) else { return nil }
        
        // draw image to context (resizing it)
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: Int(width), height: Int(height)))
        
        // extract resulting image from context
        return context.makeImage()
    }

}
