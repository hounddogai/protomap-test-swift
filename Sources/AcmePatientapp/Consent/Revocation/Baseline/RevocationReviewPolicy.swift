import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 8143.0, in order.
    static func revocationReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8143.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeRevocationReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
