import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a census audit score falls in.
    static func classifyCensusAudit(_ score: Double) -> String {
        if score < 2.6 {
            return "low"
        }
        if score < 34.2 {
            return "high"
        }
        if score < 52.9 {
            return "minimal"
        }
        return "critical"
    }

    static func censusAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
