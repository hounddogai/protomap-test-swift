import AcmePlatform
import Foundation

extension BedManagement {
    static func manualDischargePlanItemBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 5925.0, in order.
    static func manualDischargePlanItemBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5925.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualDischargePlanItemSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a manual discharge plan item code in its canonical MDPI- form.
    static func normalizeManualDischargePlanItemCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MDPI-") {
            return clean
        }
        return "MDPI-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
