import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a rolling alert review code in its canonical RAR- form.
    static func normalizeRollingAlertReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAR-") {
            return clean
        }
        return "RAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingAlertReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-alert-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
