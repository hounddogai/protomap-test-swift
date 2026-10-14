import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 65290.0, in order.
    static func legacyAccessionMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65290.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a legacy accession milestone score falls in.
    static func classifyLegacyAccessionMilestone(_ score: Double) -> String {
        if score < 14.8 {
            return "low"
        }
        if score < 21.6 {
            return "high"
        }
        if score < 33.0 {
            return "elevated"
        }
        if score < 81.3 {
            return "minimal"
        }
        return "critical"
    }
}
