//
//  Exec.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 08/11/2021.
//

import Foundation

func hideDesktop() {
    shell("defaults", "write", "com.apple.finder", "CreateDesktop", "false")
    shell("killall", "Finder")
}

func showDesktop() {
    shell("defaults", "write", "com.apple.finder", "CreateDesktop", "true")
    shell("killall", "Finder")
}

@discardableResult
func shell(_ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
