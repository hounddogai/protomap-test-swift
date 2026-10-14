import AcmePlatform
import Foundation

extension Staffing {
    static func mergeFloatPoolBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func floatPoolBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 82379.0, in order.
    static func floatPoolBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82379.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a float pool baseline score falls in.
    static func classifyFloatPoolBaseline(_ score: Double) -> String {
        if score < 3.2 {
            return "high"
        }
        if score < 51.8 {
            return "low"
        }
        if score < 77.3 {
            return "elevated"
        }
        if score < 97.2 {
            return "ok"
        }
        return "minimal"
    }
}
