import AcmePlatform
import Foundation

extension Pharmacy {
    static func strictRecallReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a strict recall review code in its canonical SRR- form.
    static func normalizeStrictRecallReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRR-") {
            return clean
        }
        return "SRR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 99884.0, in order.
    static func strictRecallReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99884.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a strict recall review score falls in.
    static func classifyStrictRecallReview(_ score: Double) -> String {
        if score < 38.8 {
            return "critical"
        }
        if score < 78.2 {
            return "high"
        }
        return "minimal"
    }
}
