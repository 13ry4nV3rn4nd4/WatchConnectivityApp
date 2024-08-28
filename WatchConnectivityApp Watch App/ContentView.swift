//
//  ContentView.swift
//  WatchConnectivityApp Watch App
//
//  Created by Bryan Vernanda on 27/08/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var watchVM = WatchVM()

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    watchVM.triggerSelfisRecording()
                    watchVM.recordUtils.sendRecordingState(watchVM.connectivity, watchVM.isRecording)
                }, label: {
                    Text(watchVM.isRecording ? "Stop Recording" : "Start Recording")
                })
                .padding()
            }
            
            List(watchVM.recordings, id: \.self) { recording in
                HStack {
                    Text(recording.lastPathComponent)
                    Spacer()
                    Button("Play") {
                        watchVM.recordUtils.playRecording(recording)
                    }
                }
            }
        }
        .onAppear {
            watchVM.requestRecordPermission()
        }
    }
}

#Preview {
    ContentView()
}
