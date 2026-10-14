import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a capped risk score claim score falls in.
    static func classifyCappedRiskScoreClaim(_ score: Double) -> String {
        if score < 93.5 {
            return "high"
        }
        if score < 95.4 {
            return "watch"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 33262.0, in order.
    static func cappedRiskScoreClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 33262.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCappedRiskScoreClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
