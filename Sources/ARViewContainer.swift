import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedPet: PetType
    var speechManager: SpeechManager
    var gameManager: GameManager
    @Binding var statusMessage: String

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)

        // Coaching overlay
        let coaching = ARCoachingOverlayView()
        coaching.translatesAutoresizingMaskIntoConstraints = false
        coaching.session = arView.session
        coaching.activatesAutomatically = true
        coaching.goal = .horizontalPlane
        arView.addSubview(coaching)
        NSLayoutConstraint.activate([
            coaching.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            coaching.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
            coaching.widthAnchor.constraint(equalTo: arView.widthAnchor),
            coaching.heightAnchor.constraint(equalTo: arView.heightAnchor)
        ])

        // Add tap gesture for placement and interactions
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        // Subscribe to frame updates (to allow pet behaviour)
        context.coordinator.cancellable = arView.scene.subscribe(to: SceneEvents.Update.self) { event in
            context.coordinator.updatePerFrame(deltaTime: event.deltaTime)
        }

        context.coordinator.arView = arView
        context.coordinator.speechManager = speechManager
        context.coordinator.gameManager = gameManager
        context.coordinator.statusPublisher = { msg in
            DispatchQueue.main.async {
                self.statusMessage = msg
            }
        }
        // Link game manager to coordinator
        gameManager.coordinator = context.coordinator

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.selectedPet = selectedPet
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedPet: selectedPet)
    }

    class Coordinator: NSObject {
        weak var arView: ARView?
        var selectedPet: PetType
        var petAnchorEntity: AnchorEntity?
        var petEntity: PetEntity?
        var speechManager: SpeechManager?
        var gameManager: GameManager?
        var statusPublisher: ((String)->Void)?
        var cancellable: Cancellable?

        init(selectedPet: PetType) {
            self.selectedPet = selectedPet
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let v = arView else { return }
            let pt = gesture.location(in: v)
            if let result = v.raycast(from: pt, allowing: .estimatedPlane, alignment: .horizontal).first {
                // Place pet if not present
                if petEntity == nil {
                    placePet(at: result.worldTransform.translation)
                    statusPublisher?("Pet placed! Tap pet to interact.")
                } else {
                    // check if tapped a pet
                    let hits = v.hitTest(pt)
                    if let _ = hits.first(where: { $0.entity == petEntity?.modelEntity || $0.entity?.parent == petEntity?.modelEntity }) {
                        // interact
                        petEntity?.reactToTap()
                        statusPublisher?("Pet petted 🥰")
                    } else {
                        // else move pet target
                        petEntity?.walkTo(position: result.worldTransform.translation)
                        statusPublisher?("Pet walking...")
                    }
                }
            }
        }

        func placePet(at pos: SIMD3<Float>) {
            guard let v = arView else { return }
            let anchor = AnchorEntity(world: pos)
            v.scene.anchors.append(anchor)
            self.petAnchorEntity = anchor
            // create PetEntity
            let pet = PetEntity(type: selectedPet)
            anchor.addChild(pet)
            pet.modelEntity?.transform.translation = [0, 0, 0]
            self.petEntity = pet
            pet.startIdleBehavior()
        }

        func updatePerFrame(deltaTime: TimeInterval) {
            petEntity?.update(deltaTime: deltaTime)
            gameManager?.update(deltaTime: deltaTime)
        }
    }
}
