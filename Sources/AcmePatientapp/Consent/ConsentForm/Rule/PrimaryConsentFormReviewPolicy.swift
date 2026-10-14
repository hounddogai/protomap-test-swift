import AcmePlatform
import Foundation

extension Consent {
    static func primaryConsentFormReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a primary consent form review code in its canonical PCFR- form.
    static func normalizePrimaryConsentFormReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCFR-") {
            return clean
        }
        return "PCFR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryConsentFormReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-consent-form-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
