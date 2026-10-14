import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeCareProtocolRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 69740.0, in order.
    static func careProtocolRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69740.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a care protocol rollup score falls in.
    static func classifyCareProtocolRollup(_ score: Double) -> String {
        if score < 19.1 {
            return "low"
        }
        if score < 47.0 {
            return "medium"
        }
        return "minimal"
    }
}
