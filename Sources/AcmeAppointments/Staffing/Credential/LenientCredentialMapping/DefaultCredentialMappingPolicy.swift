import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a default credential mapping score falls in.
    static func classifyDefaultCredentialMapping(_ score: Double) -> String {
        if score < 17.0 {
            return "watch"
        }
        if score < 40.6 {
            return "critical"
        }
        if score < 52.0 {
            return "low"
        }
        if score < 83.9 {
            return "minimal"
        }
        return "medium"
    }

    static func defaultCredentialMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
