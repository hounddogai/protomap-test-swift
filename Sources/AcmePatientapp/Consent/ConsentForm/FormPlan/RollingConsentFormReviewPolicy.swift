import AcmePlatform
import Foundation

extension Consent {
    static func rollingConsentFormReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingConsentFormReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-consent-form-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling consent form review code in its canonical RCFR- form.
    static func normalizeRollingConsentFormReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCFR-") {
            return clean
        }
        return "RCFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 66690.0, in order.
    static func rollingConsentFormReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66690.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
