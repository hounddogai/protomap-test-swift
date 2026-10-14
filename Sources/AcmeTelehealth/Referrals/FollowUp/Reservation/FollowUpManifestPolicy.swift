import AcmePlatform
import Foundation

extension Referrals {
    static func followUpManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 44917.0, in order.
    static func followUpManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44917.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a follow up manifest score falls in.
    static func classifyFollowUpManifest(_ score: Double) -> String {
        if score < 5.0 {
            return "elevated"
        }
        if score < 5.5 {
            return "high"
        }
        if score < 7.3 {
            return "medium"
        }
        return "ok"
    }
}
