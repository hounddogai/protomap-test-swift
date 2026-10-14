import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a credential budget score falls in.
    static func classifyCredentialBudget(_ score: Double) -> String {
        if score < 8.1 {
            return "ok"
        }
        if score < 48.6 {
            return "watch"
        }
        if score < 89.3 {
            return "elevated"
        }
        return "medium"
    }

    static func credentialBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
