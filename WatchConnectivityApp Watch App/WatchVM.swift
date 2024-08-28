//
//  WatchVM.swift
//  WatchConnectivityApp
//
//  Created by Bryan Vernanda on 27/08/24.
//

import AVFoundation
import Combine

class WatchVM: ObservableObject {
    @Published var recordings: [URL] = [] // to store the recordings in watch
    @Published var isRecording = false // isRecording state that can be triggered either by button on iOS or watchOS
    @Published var connectivity = WatchConnectivityManager() // use the WatchConnectivityManager to connect between watch - iOS
    var recordUtils = SharedRecordingModel() // create a sharedRecordingModel instance that will be used for the VM
    var cancellables = Set<AnyCancellable>()
    var audioRecorder: AVAudioRecorder?
    var currentAudioFilename: URL?
    
    init() {
        connectivity.isRecordingSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if isRecording != newValue {
                    triggerSelfisRecording()
                }
            }
            .store(in: &cancellables)
    }
    
    func requestRecordPermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    do {
                        try self.setupAudioSession()
                    } catch {
                        print("Failed to set up audio session: \(error.localizedDescription)")
                    }
                } else {
                    print("Permission denied")
                }
            }
        }
    }
    
    func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
        try audioSession.setActive(true)
    }
    
    func setupRecorder() throws {
        let recordingSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 192000
        ] as [String : Any]

        // Get the document directory path
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        // Create a timestamp string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        // Create the audio filename with the timestamp
        let audioFilename = documentPath.appendingPathComponent("recording-\(timestamp).m4a")
        currentAudioFilename = audioFilename

        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: recordingSettings)
        audioRecorder?.prepareToRecord()
    }
    
    func startRecording() {
        do {
            try setupRecorder()
            audioRecorder?.record()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
    }
    
    func triggerSelfisRecording() {
        // trigger this class isRecording
        isRecording.toggle()
        
        // start recording when isRecording is true and vice versa
        isRecording ? startRecording() : stopRecording()
        
        // if the recording is stopped then fetch the newest audio recording list
        if !isRecording {
            recordings = recordUtils.fetchRecordings()
            connectivity.sendRecordingToiPhone(recordings, currentAudioFilename!)
        }
    }
}
