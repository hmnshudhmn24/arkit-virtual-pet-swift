import Foundation
import RealityKit
import Combine
import simd

class GameManager: ObservableObject {
    weak var coordinator: ARViewContainer.Coordinator?
    var onMessage: ((String)->Void)?

    private var thrownBallEntity: Entity?
    private var fetchTargetPosition: SIMD3<Float>?
    private var fetchInProgress = false

    func throwBallRequested() {
        guard let coord = coordinator, let ar = coord.arView else {
            onMessage?("Place pet first.")
            return
        }
        guard let pet = coord.petEntity else {
            onMessage?("Place pet first.")
            return
        }
        // spawn ball in front of camera
        if let cam = ar.cameraTransform {
            let forward = cam.matrix.columns.2
            let spawnPos = cam.translation - SIMD3<Float>(forward.x * 0.2, forward.y * 0.1, forward.z * 0.2)
            spawnBall(at: spawnPos, initialVelocity: -SIMD3<Float>(forward.x, forward.y, forward.z) * 1.6)
            onMessage?("Ball thrown!")
        }
    }

    func spawnBall(at position: SIMD3<Float>, initialVelocity: SIMD3<Float>) {
        guard let coord = coordinator, let ar = coord.arView else { return }
        let ball = ModelEntity(mesh: .generateSphere(radius: 0.03), materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
        ball.position = position
        ball.generateCollisionShapes(recursive: true)
        let anchor = AnchorEntity(world: position)
        anchor.addChild(ball)
        ar.scene.addAnchor(anchor)
        // simple physics-ish movement using a coroutine-like update
        self.thrownBallEntity = ball
        self.fetchTargetPosition = coord.petEntity?.transform.translation
        self.fetchInProgress = true
    }

    func feedRequested() {
        guard let coord = coordinator, let pet = coord.petEntity else {
            onMessage?("Can't feed yet — place a pet first.")
            return
        }
        // drop snack in front of pet
        let petPos = pet.transform.translation
        let snackPos = petPos + SIMD3<Float>(0.15, 0, 0.15)
        pet.eat(at: snackPos)
        onMessage?("Yum! Pet ate the snack 🦴")
    }

    func playFetchRequested() {
        if fetchInProgress {
            onMessage?("Fetch in progress!")
            return
        }
        throwBallRequested()
    }

    func handleVoiceCommand(command: String) {
        guard let coord = coordinator else { return }
        if command.contains("sit") {
            coord.petEntity?.reactToTap()
            onMessage?("Pet sits (cute!).")
        } else if command.contains("jump") {
            // simple jump: move up & down
            if let me = coord.petEntity?.modelEntity {
                me.move(to: Transform(translation: me.transform.translation + [0,0.15,0]), relativeTo: coord.petEntity, duration: 0.25)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    me.move(to: Transform(translation: me.transform.translation), relativeTo: coord.petEntity, duration: 0.2)
                }
                onMessage?("Pet jumped!")
            }
        } else if command.contains("fetch") {
            playFetchRequested()
        } else if command.contains("come") || command.contains("here") {
            // move pet to camera position
            if let ar = coord.arView, let cam = ar.cameraTransform {
                let camPos = cam.translation
                coord.petEntity?.walkTo(position: camPos)
                onMessage?("Pet coming!")
            }
        } else {
            onMessage?("I didn't understand. Try 'sit', 'jump', or 'fetch'.")
        }
    }

    func update(deltaTime: TimeInterval) {
        // animate thrown ball towards pet and trigger fetch when close
        guard let coord = coordinator, let ar = coord.arView else { return }
        if let ball = thrownBallEntity, let pet = coord.petEntity, let ballAnchor = ball.anchor {
            // simple translation towards fetch target (pet), not real physics
            let bpos = ball.transform.translation
            let tpos = pet.transform.translation
            let dir = tpos - bpos
            let dist = length(dir)
            let step = Float(deltaTime) * 1.2
            if dist > 0.03 {
                ball.transform.translation += normalize(dir) * step
            } else {
                // pet "fetches" the ball
                pet.reactToTap()
                // remove ball
                ballAnchor.removeFromParent()
                thrownBallEntity = nil
                fetchInProgress = false
                onMessage?("Pet fetched the ball! 🎉")
            }
        }
    }
}
