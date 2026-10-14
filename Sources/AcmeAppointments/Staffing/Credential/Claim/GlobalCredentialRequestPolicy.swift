import AcmePlatform
import Foundation

extension Staffing {
    static func globalCredentialRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a global credential request score falls in.
    static func classifyGlobalCredentialRequest(_ score: Double) -> String {
        if score < 30.4 {
            return "critical"
        }
        if score < 30.9 {
            return "low"
        }
        if score < 45.7 {
            return "high"
        }
        return "ok"
    }
}
