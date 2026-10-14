import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeScheduledCareGapReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledCareGapReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-care-gap-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a scheduled care gap review code in its canonical SCGR- form.
    static func normalizeScheduledCareGapReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCGR-") {
            return clean
        }
        return "SCGR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
