import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a eligibility rollup score falls in.
    static func classifyEligibilityRollup(_ score: Double) -> String {
        if score < 36.2 {
            return "watch"
        }
        if score < 62.0 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a eligibility rollup code in its canonical ER- form.
    static func normalizeEligibilityRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ER-") {
            return clean
        }
        return "ER-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
