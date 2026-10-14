import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a strict courier target score falls in.
    static func classifyStrictCourierTarget(_ score: Double) -> String {
        if score < 18.7 {
            return "watch"
        }
        if score < 72.7 {
            return "minimal"
        }
        if score < 76.5 {
            return "low"
        }
        return "ok"
    }

    static func mergeStrictCourierTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 69738.0, in order.
    static func strictCourierTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69738.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
