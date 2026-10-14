import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeAdaptiveRecallReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a adaptive recall review code in its canonical ARR- form.
    static func normalizeAdaptiveRecallReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ARR-") {
            return clean
        }
        return "ARR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveRecallReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-recall-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
