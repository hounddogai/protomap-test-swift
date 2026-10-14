import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a global specimen review score falls in.
    static func classifyGlobalSpecimenReview(_ score: Double) -> String {
        if score < 35.2 {
            return "low"
        }
        if score < 39.0 {
            return "watch"
        }
        return "minimal"
    }

    /// Puts a global specimen review code in its canonical GSR- form.
    static func normalizeGlobalSpecimenReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSR-") {
            return clean
        }
        return "GSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalSpecimenReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-specimen-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func globalSpecimenReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
