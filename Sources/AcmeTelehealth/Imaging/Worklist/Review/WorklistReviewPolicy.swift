import AcmePlatform
import Foundation

extension Imaging {
    static func worklistReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a worklist review code in its canonical WR- form.
    static func normalizeWorklistReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WR-") {
            return clean
        }
        return "WR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a worklist review score falls in.
    static func classifyWorklistReview(_ score: Double) -> String {
        if score < 63.2 {
            return "high"
        }
        if score < 80.0 {
            return "low"
        }
        if score < 88.9 {
            return "critical"
        }
        if score < 94.6 {
            return "elevated"
        }
        return "watch"
    }
}
