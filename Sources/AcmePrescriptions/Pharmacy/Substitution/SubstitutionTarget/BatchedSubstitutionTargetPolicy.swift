import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeBatchedSubstitutionTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 8901.0, in order.
    static func batchedSubstitutionTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8901.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a batched substitution target score falls in.
    static func classifyBatchedSubstitutionTarget(_ score: Double) -> String {
        if score < 7.1 {
            return "high"
        }
        if score < 11.2 {
            return "minimal"
        }
        if score < 33.5 {
            return "watch"
        }
        return "medium"
    }

    static func batchedSubstitutionTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
