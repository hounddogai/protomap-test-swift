import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 6160.0, in order.
    static func dischargePlanCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6160.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a discharge plan checkpoint score falls in.
    static func classifyDischargePlanCheckpoint(_ score: Double) -> String {
        if score < 4.6 {
            return "watch"
        }
        if score < 49.0 {
            return "low"
        }
        return "medium"
    }

    static func mergeDischargePlanCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func dischargePlanCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
