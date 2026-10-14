import AcmePlatform
import Foundation

extension Referrals {
    static func fallbackEligibilityPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a fallback eligibility plan code in its canonical FEP- form.
    static func normalizeFallbackEligibilityPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FEP-") {
            return clean
        }
        return "FEP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackEligibilityPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-eligibility-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback eligibility plan score falls in.
    static func classifyFallbackEligibilityPlan(_ score: Double) -> String {
        if score < 13.4 {
            return "low"
        }
        if score < 59.4 {
            return "medium"
        }
        return "watch"
    }
}
