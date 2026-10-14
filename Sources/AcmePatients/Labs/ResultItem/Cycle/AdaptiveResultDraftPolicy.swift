import AcmePlatform
import Foundation

extension Labs {
    static func mergeAdaptiveResultDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveResultDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 22026.0, in order.
    static func adaptiveResultDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22026.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
