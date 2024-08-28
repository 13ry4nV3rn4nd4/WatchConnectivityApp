//
//  Utils.swift
//  WatchConnectivityApp
//
//  Created by Bryan Vernanda on 27/08/24.
//

import AVFoundation

class SharedRecordingModel {
    var audioPlayer: AVAudioPlayer?
    
    func playRecording(_ recording: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording)
            audioPlayer?.play()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }
    
    func fetchRecordings() -> [URL] {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil, options: [])
            let newRecordings = files.filter { $0.pathExtension == "m4a" }
            
            let allRecordings = newRecordings.sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
            
            print("fetched Recording: \(allRecordings)")
            
            return allRecordings
        } catch {
            print("Failed to fetch recordings: \(error.localizedDescription)")
            return []
        }
    }
    
    func sendRecordingState(_ connectivity: WatchConnectivityManager, _ isRecording: Bool) {
        connectivity.sendStateChangeRequest(isRecording)
    }
}
