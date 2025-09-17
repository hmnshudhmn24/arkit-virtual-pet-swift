import RealityKit
import Combine
import Foundation
import simd

enum PetType: String, CaseIterable {
    case dog, cat, dragon
}

class PetEntity: Entity, HasModel, HasAnchoring {
    var modelEntity: ModelEntity?
    var type: PetType
    private var targetPosition: SIMD3<Float>?
    private var speed: Float = 0.3 // m/s
    private var idleTimer: TimeInterval = 0
    private var cancellables = Set<AnyCancellable>()

    init(type: PetType) {
        self.type = type
        super.init()
        loadModel()
    }

    required init() {
        fatalError("init() not implemented")
    }

    private func loadModel() {
        // Attempt to load a USDZ from bundle — fallback to simple model
        let name = "pet_\(type.rawValue)"
        if let url = Bundle.main.url(forResource: name, withExtension: "usdz") {
            let entity = try? ModelEntity.loadModel(contentsOf: url)
            if let ent = entity {
                self.modelEntity = ent
                self.addChild(ent)
                ent.generateCollisionShapes(recursive: true)
                return
            }
        }

        // Fallback: programmatic simple model
        let mesh: MeshResource
        switch type {
        case .dog, .cat:
            mesh = .generateSphere(radius: 0.08)
        case .dragon:
            mesh = .generateSphere(radius: 0.12)
        }
        let material = SimpleMaterial(color: .init(red: 0.9, green: 0.8, blue: 0.6), isMetallic: false)
        let m = ModelEntity(mesh: mesh, materials: [material])
        m.generateCollisionShapes(recursive: true)
        self.modelEntity = m
        self.addChild(m)
    }

    func startIdleBehavior() {
        idleTimer = 0
        // small idle bob animation
        if let me = modelEntity {
            let up = Transform(scale: me.transform.scale, rotation: me.transform.rotation, translation: me.transform.translation + [0, 0.02, 0])
            let down = Transform(scale: me.transform.scale, rotation: me.transform.rotation, translation: me.transform.translation)
            me.move(to: up, relativeTo: self, duration: 1.2, timingFunction: .easeInOut)
            me.move(to: down, relativeTo: self, duration: 1.2, timingFunction: .easeInOut)
        }
    }

    func walkTo(position: SIMD3<Float>) {
        targetPosition = position
    }

    func reactToTap() {
        // simple scale-up bounce
        guard let me = modelEntity else { return }
        me.scale += [0.02, 0.02, 0.02]
        me.move(to: me.transform, relativeTo: self, duration: 0.1)
        // return to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            me.scale = [1,1,1]
        }
    }

    func eat(at pos: SIMD3<Float>) {
        // small animation to look toward pos and do "eat"
        lookAt(target: pos)
        // simulate chewing (scale down/up)
        if let me = modelEntity {
            me.move(to: Transform(scale: me.scale * 0.95, rotation: me.transform.rotation, translation: me.transform.translation), relativeTo: self, duration: 0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                me.move(to: Transform(scale: me.scale / 0.95, rotation: me.transform.rotation, translation: me.transform.translation), relativeTo: self, duration: 0.1)
            }
        }
    }

    func lookAt(target: SIMD3<Float>) {
        // rotate to face target (very simple)
        guard let me = modelEntity else { return }
        let dir = normalize(target - self.transform.translation)
        let up: SIMD3<Float> = [0,1,0]
        let zAxis = -dir
        // Construct quaternion roughly (not precise)
        // For simplicity skip exact rotation math
    }

    func update(deltaTime: TimeInterval) {
        idleTimer += deltaTime
        // move towards target if present
        if let target = targetPosition {
            let pos = self.transform.translation
            var dir = target - pos
            let dist = length(dir)
            if dist < 0.02 {
                targetPosition = nil
                // arrived — small bounce
                if let me = modelEntity {
                    me.move(to: Transform(scale: me.scale * 1.02, rotation: me.transform.rotation, translation: me.transform.translation), relativeTo: self, duration: 0.15)
                }
            } else {
                dir = dir / dist
                let movement = dir * Float(speed) * Float(deltaTime)
                self.transform.translation += movement
            }
        } else {
            // idle wander occasionally
            if idleTimer > 5.0 {
                // wander small random step
                idleTimer = 0
                let rx = Float.random(in: -0.15...0.15)
                let rz = Float.random(in: -0.15...0.15)
                let newPos = self.transform.translation + [rx, 0, rz]
                walkTo(position: newPos)
            }
        }
    }
}
