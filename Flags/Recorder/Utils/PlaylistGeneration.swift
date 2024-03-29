//
//  PlaylistGeneration.swift
//  Flags
//
//  Created by Archie Edwards on 02/11/2021.
//

import Foundation
import AVFoundation

func updatePlaylistForSegment(state: IndexFileState, segment: Segment) -> IndexFileState {
    var newState = state
    let segmentFileName = segment.fileName(forPrefix: segmentFileNamePrefix)
    
    if segment.isInitializationSegment {
        // There is only one initialization segment, and it comes first.  Add the initial tags to the index file.
        assert(newState.content == "")
        newState.content = "#EXTM3U\n"
            + "#EXT-X-TARGETDURATION:\(segmentDuration)\n"
            + "#EXT-X-VERSION:7\n"
            + "#EXT-X-MEDIA-SEQUENCE:1\n"
            + "#EXT-X-PLAYLIST-TYPE:VOD\n"
            + "#EXT-X-INDEPENDENT-SEGMENTS\n"
            + "#EXT-X-MAP:URI=\"\(segmentFileName)\"\n"
    }else {
        /*
            For each separable segment, calculate the duration of the previous segment and add an entry for that segment to the index file.
            When the HLS stream will have both audio and video, prefer the video track's timing when calculating the segment duration.
            Although AVAssetSegmentTrackReport has a duration property, this represents the decode duration.
            In order to properly calculate the value for #EXTINF, you need the presentation duration.
            To calculate presentation duration of the previous segment, take the difference between this segment's presentation time stamp
            and the previous segment's presentation timestamp.
        */
        let segmentReport = segment.report! // A separable segment will always include a segment report.
        let timingTrackReport = segmentReport.trackReports.first(where: { $0.mediaType == .video })!
        if let previousSegmentInfo = state.previousSegmentInfo {
            let segmentDuration = timingTrackReport.earliestPresentationTimeStamp - previousSegmentInfo.timingTrackReport.earliestPresentationTimeStamp
            
            newState.content = state.content
                + "#EXTINF:\(String(format: "%1.5f", segmentDuration.seconds)),\t\n"
                + "\(previousSegmentInfo.fileName)\n"
        }
        
        // Stash away the current segment to refer back to when you get the next segment.
        newState.previousSegmentInfo = (segmentFileName, timingTrackReport)
    }
    
    return newState
}

func generateFullPlaylist(state: IndexFileState) -> String {
    let nearFinalIndexFile: String
    
    // Append an entry for the final segment, if there were any segments.
    // Here you use the duration property because there is no time stamp available for the end of the segment.
    if let finalSegmentInfo = state.previousSegmentInfo {
        let segmentDuration = finalSegmentInfo.timingTrackReport.duration
        
        nearFinalIndexFile = state.content
            + "#EXTINF:\(String(format: "%1.5f", segmentDuration.seconds)),\t\n"
            + "\(finalSegmentInfo.fileName)\n"
    } else {
        nearFinalIndexFile = state.content
    }
    
    // Add the closing tag.
    return nearFinalIndexFile
        + "#EXT-X-ENDLIST\n"
}

struct IndexFileState {
    var content = ""
    var previousSegmentInfo: (fileName: String, timingTrackReport: AVAssetSegmentTrackReport)?
}
