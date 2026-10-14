import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeConsentFormReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("consent-form-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a consent form review code in its canonical CFR- form.
    static func normalizeConsentFormReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFR-") {
            return clean
        }
        return "CFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func consentFormReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
