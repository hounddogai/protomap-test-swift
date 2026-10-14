import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 64072.0, in order.
    static func isolationMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64072.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeIsolationMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a isolation milestone score falls in.
    static func classifyIsolationMilestone(_ score: Double) -> String {
        if score < 87.4 {
            return "low"
        }
        if score < 95.7 {
            return "minimal"
        }
        return "critical"
    }

    static func isolationMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
