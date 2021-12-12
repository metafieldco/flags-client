//
//  Exec.swift
//  Flags
//
//  Created by Archie Edwards on 08/11/2021.
//

import Foundation

func toggleDesktop(hide: Bool) {
    DispatchQueue.main.async {
        let desktopUrl = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!

        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: desktopUrl, includingPropertiesForKeys: nil)

            for var content in directoryContents {
                content.isHidden = hide
            }
        } catch {
            print(error)
        }
    }
}

extension URL {
    var isHidden: Bool {
        get {
            return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = newValue
            do {
                try setResourceValues(resourceValues)
            } catch {
                print("isHidden error:", error)
            }
        }
    }
}
