import AcmePlatform
import Foundation

extension BedManagement {
    static func cappedCleaningSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Names the band a capped cleaning slot score falls in.
    static func classifyCappedCleaningSlot(_ score: Double) -> String {
        if score < 3.9 {
            return "ok"
        }
        if score < 44.1 {
            return "minimal"
        }
        return "elevated"
    }

    static func mergeCappedCleaningSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 30864.0, in order.
    static func cappedCleaningSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30864.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
