import AcmePlatform
import Foundation

extension Staffing {
    static func mergeFloatPoolScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a float pool score score falls in.
    static func classifyFloatPoolScore(_ score: Double) -> String {
        if score < 31.4 {
            return "medium"
        }
        if score < 38.3 {
            return "ok"
        }
        return "high"
    }

    static func floatPoolScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Counts how many amounts fit in a budget of 571.0, in order.
    static func floatPoolScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 571.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
