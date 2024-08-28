//
//  ContentView.swift
//  WatchConnectivityApp
//
//  Created by Bryan Vernanda on 27/08/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var iosVM = iOSVM()
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    iosVM.triggerSelfisRecording()
                    iosVM.recordUtils.sendRecordingState(iosVM.connectivity, iosVM.isRecording)
                }, label: {
                    Text(iosVM.isRecording ? "Stop Recording" : "Start Recording")
                })
                .padding()
            }
            
            List(iosVM.recordings, id: \.self) { recording in
                HStack {
                    Text(recording.lastPathComponent)
                    Spacer()
                    Button("Play") {
                        iosVM.recordUtils.playRecording(recording)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
