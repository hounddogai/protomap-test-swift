import AcmePlatform
import Foundation

extension ClinicalOps {
    static func primaryRoundingSlotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a primary rounding slot code in its canonical PRS- form.
    static func normalizePrimaryRoundingSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRS-") {
            return clean
        }
        return "PRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 52149.0, in order.
    static func primaryRoundingSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52149.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func primaryRoundingSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
