import AcmePlatform
import Foundation

extension BedManagement {
    static func adaptiveDischargePlanMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a adaptive discharge plan mapping score falls in.
    static func classifyAdaptiveDischargePlanMapping(_ score: Double) -> String {
        if score < 86.3 {
            return "high"
        }
        if score < 96.9 {
            return "elevated"
        }
        if score < 98.4 {
            return "medium"
        }
        return "low"
    }
}
