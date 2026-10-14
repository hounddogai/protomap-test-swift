import AcmePlatform
import Foundation

extension Staffing {
    static func mergeManualShiftAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 59972.0, in order.
    static func manualShiftAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 59972.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual shift adjustment score falls in.
    static func classifyManualShiftAdjustment(_ score: Double) -> String {
        if score < 39.5 {
            return "medium"
        }
        if score < 46.2 {
            return "watch"
        }
        if score < 83.5 {
            return "critical"
        }
        if score < 98.3 {
            return "low"
        }
        return "minimal"
    }
}
