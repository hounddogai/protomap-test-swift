import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a language audit score falls in.
    static func classifyLanguageAudit(_ score: Double) -> String {
        if score < 57.1 {
            return "low"
        }
        if score < 71.3 {
            return "critical"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLanguageAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("language-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func languageAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.19
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
