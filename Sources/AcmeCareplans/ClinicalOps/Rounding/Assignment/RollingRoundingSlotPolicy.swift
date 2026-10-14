import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 84723.0, in order.
    static func rollingRoundingSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84723.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingRoundingSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a rolling rounding slot score falls in.
    static func classifyRollingRoundingSlot(_ score: Double) -> String {
        if score < 5.6 {
            return "medium"
        }
        if score < 57.0 {
            return "elevated"
        }
        if score < 75.0 {
            return "ok"
        }
        if score < 83.7 {
            return "watch"
        }
        return "low"
    }

    /// Puts a rolling rounding slot code in its canonical RRS- form.
    static func normalizeRollingRoundingSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRS-") {
            return clean
        }
        return "RRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
