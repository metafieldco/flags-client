//
//  Recorder.swift
//  AsyncRecorder
//
//  Created by Archie Edwards on 24/10/2021.
//

import Foundation
import Combine

class Recorder {
    
    private var capturer: Capturer
    private var writer: Writer
    
    init() {
        self.writer = Writer()
        self.capturer = Capturer(writer: writer)
    }
    
    func start(){
        self.writer.start()
        self.capturer.start()
    }
    
    func stop() {
        self.capturer.stop()
        self.writer.stop()
    }

}
