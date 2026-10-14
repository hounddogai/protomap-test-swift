import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a adaptive consent form review score falls in.
    static func classifyAdaptiveConsentFormReview(_ score: Double) -> String {
        if score < 7.1 {
            return "critical"
        }
        if score < 58.4 {
            return "watch"
        }
        if score < 85.9 {
            return "medium"
        }
        return "low"
    }

    static func adaptiveConsentFormReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a adaptive consent form review code in its canonical ACFR- form.
    static func normalizeAdaptiveConsentFormReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACFR-") {
            return clean
        }
        return "ACFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveConsentFormReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-consent-form-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
