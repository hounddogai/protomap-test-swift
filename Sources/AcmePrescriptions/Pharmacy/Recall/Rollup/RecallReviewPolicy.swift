import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRecallReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("recall-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a recall review code in its canonical RR- form.
    static func normalizeRecallReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RR-") {
            return clean
        }
        return "RR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func recallReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a recall review score falls in.
    static func classifyRecallReview(_ score: Double) -> String {
        if score < 6.0 {
            return "medium"
        }
        if score < 9.6 {
            return "ok"
        }
        if score < 42.6 {
            return "critical"
        }
        return "elevated"
    }
}
