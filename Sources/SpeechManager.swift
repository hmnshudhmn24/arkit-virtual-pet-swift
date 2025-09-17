import Foundation
import Speech
import AVFoundation
import Combine

final class SpeechManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    var onCommand: ((String)->Void)?

    init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { auth in
            // handle states if needed
        }
    }

    func startListening() {
        // if already running, stop
        if audioEngine.isRunning {
            stopListening()
            return
        }
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let request = recognitionRequest else { return }
            let node = audioEngine.inputNode
            let format = node.outputFormat(forBus: 0)
            node.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, _) in
                request.append(buffer)
            }
            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                if let r = result, r.isFinal {
                    let text = r.bestTranscription.formattedString
                    self?.onCommand?(text.lowercased())
                    self?.stopListening()
                } else if let _ = error {
                    self?.stopListening()
                }
            }
        } catch {
            print("Speech start error: \(error)")
        }
    }

    func stopListening() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }
}
