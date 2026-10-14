import AcmePlatform
import Foundation

extension Staffing {
    static func credentialAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a credential audit score falls in.
    static func classifyCredentialAudit(_ score: Double) -> String {
        if score < 23.4 {
            return "watch"
        }
        if score < 41.0 {
            return "ok"
        }
        if score < 60.7 {
            return "minimal"
        }
        return "medium"
    }
}
