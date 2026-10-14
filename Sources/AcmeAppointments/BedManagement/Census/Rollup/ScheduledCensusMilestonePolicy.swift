import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 75541.0, in order.
    static func scheduledCensusMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75541.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a scheduled census milestone code in its canonical SCM- form.
    static func normalizeScheduledCensusMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCM-") {
            return clean
        }
        return "SCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledCensusMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func scheduledCensusMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
