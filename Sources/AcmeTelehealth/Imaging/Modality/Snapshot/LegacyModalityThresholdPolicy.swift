import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 79235.0, in order.
    static func legacyModalityThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79235.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func legacyModalityThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeLegacyModalityThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
