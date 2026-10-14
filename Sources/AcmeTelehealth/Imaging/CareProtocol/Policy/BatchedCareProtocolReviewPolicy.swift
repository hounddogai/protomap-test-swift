import AcmePlatform
import Foundation

extension Imaging {
    static func batchedCareProtocolReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 90885.0, in order.
    static func batchedCareProtocolReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 90885.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched care protocol review code in its canonical BCPR- form.
    static func normalizeBatchedCareProtocolReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCPR-") {
            return clean
        }
        return "BCPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedCareProtocolReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
