import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a credential template score falls in.
    static func classifyCredentialTemplate(_ score: Double) -> String {
        if score < 43.7 {
            return "medium"
        }
        if score < 62.0 {
            return "high"
        }
        if score < 74.1 {
            return "low"
        }
        return "ok"
    }

    static func credentialTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
