//
//  WatchConnectivityManager.swift
//  WatchConnectivityApp
//
//  Created by Bryan Vernanda on 27/08/24.
//

import Combine
import WatchConnectivity

enum recordSent: String {
    case recordFile = "recordFile"
}

enum messageSent: String {
    case recordState = "recordState"
}

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    // is used for re-fetching newest audio list after file is received
    // currently only used on iOS and not the watch, since the file transfer is done from watch to iOS only
    var isReceivedSubject = CurrentValueSubject<Bool, Never>(false)
    var isReceived: Bool {
        get { isReceivedSubject.value }
        set { isReceivedSubject.send(newValue) }
    }
    
    // isRecordingSubject and isRecording are essential for ensuring that the recording state changes seamlessly between the Watch and iOS
    var isRecordingSubject = CurrentValueSubject<Bool, Never>(false)
    var isRecording: Bool {
        get { isRecordingSubject.value }
        set { isRecordingSubject.send(newValue) }
    }
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session =  WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
#if os(iOS)
    // function is not used in this demo but is needed to conform to protocol WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        // function to check for the activation state between iOS and Watch
    }
    
    // function is not used in this demo but is needed to conform to protocol WCSessionDelegate
    func sessionDidBecomeInactive(_ session: WCSession) {
        // function to check for the activation state between iOS and Watch
    }
    
    // function is not used in this demo but is needed to conform to protocol WCSessionDelegate
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }

#else
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        // Provide some implementation or comment on watchOS specifics if necessary
    }
    
    func sendRecordingToiPhone(_ recordings: [URL], _ currentFileName: URL) {
        guard let recordingURL = recordings.first(where: { $0.lastPathComponent == currentFileName.lastPathComponent }),
              FileManager.default.fileExists(atPath: recordingURL.path) else {
            print("File does not exist at path: \(currentFileName.path)")
            return
        }
        
        sendFile(recordingURL, recordSent.recordFile.rawValue)
    }

#endif
    
    // function to receive message from the iOS/watch which is after sendStateChangeRequest is called from the paired device
    // if sendStateChangeRequest is called from the iOS then this function will run on the watch and vice versa
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let request = message[messageSent.recordState.rawValue] as? Bool {
            self.isRecording = request
        }
    }
    
    // the first function that will be called from the iOS and Watch ViewModel to trigger record state changes
    func sendStateChangeRequest(_ isRecording: Bool) {
        let session = WCSession.default
        if session.activationState == .activated {
            session.sendMessage([messageSent.recordState.rawValue: isRecording], replyHandler: nil) { error in
                print("Error sending request: \(error.localizedDescription)")
            }
        } else {
            print("Session is not activated")
        }
    }
    
    // function to receive file either from watch/iOS
    // currently this method only runs on the iOS since the audio data is sent one way from watch to iOS
    // feel free to move this function to the "os(iOS)" part above
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let key = file.metadata?.keys.first, let recordSent = recordSent(rawValue: key) else {
            print("Unknown or missing metadata key.")
            return
        }
        
        switch recordSent {
            case .recordFile:
                if let fileName = file.metadata?[recordSent.rawValue] as? String {
                    let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
                    print("Saving file to: \(destinationURL.path)")
                    
                    do {
                        try FileManager.default.moveItem(at: file.fileURL, to: destinationURL)
                        print("File moved successfully to: \(destinationURL.path)")
                        
                        // is used only for re-fetching newest audio list on the iOS, after file is received
                        self.isReceived.toggle()
                        
                    } catch {
                        print("Failed to save file: \(error.localizedDescription)")
                    }
                }
        }
    }
    
    // function to send file either from watch/iOS
    // currently this method only runs on the watch since only the watch that sends audio file to iOS
    // feel free to move this function to the "os(watchOS)" part above
    func sendFile(_ url: URL, _ fileName: String) {
        let session = WCSession.default
        if session.activationState == .activated {
            // Pass the correct file name in the metadata
            let metadata = [fileName: url.lastPathComponent]
            let fileTransfer = session.transferFile(url, metadata: metadata)
            print("File transfer initiated for: \(url.lastPathComponent)")

            // Monitor the progress of the file transfer
            fileTransfer.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: nil)
        } else {
            print("Session is not activated")
        }
    }

    
    // to maintain file progress completion, since right now, after iOS 17.5 & WatchOS 10.5 update,
    // there is an issue in the File transfer where the callback session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) did not fire at all and the file transfer gets stuck.
    // therefore, this function is made to handle the error.
    // read more on https://forums.developer.apple.com/forums/thread/751623?page=2
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "fractionCompleted", let progress = object as? Progress {
            print("Transfer progress: \(progress.fractionCompleted * 100)%")
            
            if progress.fractionCompleted == 1.0 {
                // Transfer is complete
                print("File transfer completed successfully.")
                
                // Remove observer to prevent memory leaks
                progress.removeObserver(self, forKeyPath: "fractionCompleted")
            }
        }
    }
    
}
