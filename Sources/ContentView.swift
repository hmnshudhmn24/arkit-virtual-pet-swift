import SwiftUI
import RealityKit
import ARKit

struct ContentView: View {
    @StateObject private var speech = SpeechManager()
    @StateObject private var game = GameManager()
    @State private var selectedPet: PetType = .dog
    @State private var showControls = true
    @State private var topMessage: String = "Tap the plane to place your pet 🐾"

    var body: some View {
        ZStack {
            ARViewContainer(selectedPet: $selectedPet, speechManager: speech, gameManager: game, statusMessage: $topMessage)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Picker("", selection: $selectedPet) {
                            Text("Dog").tag(PetType.dog)
                            Text("Cat").tag(PetType.cat)
                            Text("Dragon").tag(PetType.dragon)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(10)
                        .padding(.horizontal)

                        Button(action: {
                            showControls.toggle()
                        }) {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }

                Spacer()

                VStack(spacing: 8) {
                    Text(topMessage)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    if showControls {
                        HStack(spacing: 16) {
                            Button(action: { game.throwBallRequested() }) {
                                ControlButton(label: "Throw Ball", icon: "tennisball.fill")
                            }
                            Button(action: { game.feedRequested() }) {
                                ControlButton(label: "Feed", icon: "leaf.fill")
                            }
                            Button(action: { speech.startListening() }) {
                                ControlButton(label: "Voice", icon: "mic.fill")
                            }
                            Button(action: { game.playFetchRequested() }) {
                                ControlButton(label: "Fetch", icon: "arrow.triangle.2.circlepath")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onAppear {
            speech.onCommand = { command in
                topMessage = "Heard: \(command)"
                game.handleVoiceCommand(command: command)
            }
            game.onMessage = { message in
                topMessage = message
            }
        }
    }
}

struct ControlButton: View {
    let label: String
    let icon: String
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.white)
        }
        .frame(width: 90, height: 48)
        .background(Color.blue.opacity(0.85))
        .cornerRadius(12)
    }
}
