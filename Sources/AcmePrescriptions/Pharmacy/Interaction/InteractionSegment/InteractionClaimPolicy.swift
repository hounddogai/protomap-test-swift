import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 84600.0, in order.
    static func interactionClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84600.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeInteractionClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a interaction claim score falls in.
    static func classifyInteractionClaim(_ score: Double) -> String {
        if score < 21.2 {
            return "watch"
        }
        if score < 52.8 {
            return "ok"
        }
        return "elevated"
    }

    static func interactionClaimBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
