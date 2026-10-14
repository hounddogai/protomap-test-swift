import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 77427.0, in order.
    static func globalInteractionBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77427.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global interaction baseline score falls in.
    static func classifyGlobalInteractionBaseline(_ score: Double) -> String {
        if score < 39.7 {
            return "medium"
        }
        if score < 44.7 {
            return "ok"
        }
        if score < 88.4 {
            return "low"
        }
        if score < 93.7 {
            return "watch"
        }
        return "critical"
    }

    static func globalInteractionBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeGlobalInteractionBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
