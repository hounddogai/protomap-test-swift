import AcmePlatform
import Foundation

extension Staffing {
    static func floatPoolTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a float pool target score falls in.
    static func classifyFloatPoolTarget(_ score: Double) -> String {
        if score < 45.7 {
            return "elevated"
        }
        if score < 85.7 {
            return "ok"
        }
        return "high"
    }
}
