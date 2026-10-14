import AcmePlatform
import Foundation

extension Labs {
    /// Puts a tiered reference range review code in its canonical TRRR- form.
    static func normalizeTieredReferenceRangeReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TRRR-") {
            return clean
        }
        return "TRRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredReferenceRangeReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Counts how many amounts fit in a budget of 62209.0, in order.
    static func tieredReferenceRangeReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 62209.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredReferenceRangeReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-reference-range-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
