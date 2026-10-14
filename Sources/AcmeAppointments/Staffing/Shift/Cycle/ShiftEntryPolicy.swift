import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a shift entry score falls in.
    static func classifyShiftEntry(_ score: Double) -> String {
        if score < 24.6 {
            return "watch"
        }
        if score < 28.8 {
            return "elevated"
        }
        return "critical"
    }

    static func shiftEntryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeShiftEntryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 68689.0, in order.
    static func shiftEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68689.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
