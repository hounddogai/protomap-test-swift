import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 91116.0, in order.
    static func readMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91116.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a read milestone score falls in.
    static func classifyReadMilestone(_ score: Double) -> String {
        if score < 12.2 {
            return "ok"
        }
        if score < 38.8 {
            return "low"
        }
        if score < 70.2 {
            return "critical"
        }
        if score < 98.8 {
            return "watch"
        }
        return "minimal"
    }

    static func readMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeReadMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
