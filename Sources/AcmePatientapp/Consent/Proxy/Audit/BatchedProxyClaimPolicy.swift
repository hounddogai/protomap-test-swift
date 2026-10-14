import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 55893.0, in order.
    static func batchedProxyClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 55893.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeBatchedProxyClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func batchedProxyClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
