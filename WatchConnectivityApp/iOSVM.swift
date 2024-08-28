//
//  iOSVM.swift
//  WatchConnectivityApp
//
//  Created by Bryan Vernanda on 27/08/24.
//

import Foundation
import Combine

class iOSVM: ObservableObject {
    @Published var recordings: [URL] = [] // to store the recordings in iOS
    @Published var isRecording = false // isRecording state that can be triggered either by button on iOS or watchOS
    @Published var connectivity = WatchConnectivityManager() // use the WatchConnectivityManager to connect between iOS - watch
    var recordUtils = SharedRecordingModel() // create a sharedRecordingModel instance that will be used for this VM
    var cancellables = Set<AnyCancellable>()
    
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
        
        connectivity.isReceivedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if newValue {
                    recordings = recordUtils.fetchRecordings()
                    connectivity.isReceived.toggle()
                }
            }
            .store(in: &cancellables)
    }
    
    func triggerSelfisRecording() {
        // trigger this class isRecording
        isRecording.toggle()
    }
}
