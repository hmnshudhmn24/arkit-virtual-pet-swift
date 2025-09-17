import simd
import ARKit

extension float4x4 {
    var translation: SIMD3<Float> {
        let t = columns.3
        return SIMD3<Float>(t.x, t.y, t.z)
    }
}

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        let t = columns.3
        return SIMD3<Float>(t.x, t.y, t.z)
    }
}
