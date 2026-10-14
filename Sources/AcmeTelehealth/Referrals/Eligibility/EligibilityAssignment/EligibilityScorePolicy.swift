import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a eligibility score code in its canonical ES- form.
    static func normalizeEligibilityScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ES-") {
            return clean
        }
        return "ES-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func eligibilityScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a eligibility score score falls in.
    static func classifyEligibilityScore(_ score: Double) -> String {
        if score < 40.7 {
            return "minimal"
        }
        if score < 79.9 {
            return "watch"
        }
        if score < 83.4 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeEligibilityScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("eligibility-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
