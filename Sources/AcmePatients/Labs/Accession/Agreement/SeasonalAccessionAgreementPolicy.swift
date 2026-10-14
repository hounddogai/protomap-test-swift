import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a seasonal accession agreement score falls in.
    static func classifySeasonalAccessionAgreement(_ score: Double) -> String {
        if score < 24.3 {
            return "watch"
        }
        if score < 35.7 {
            return "elevated"
        }
        if score < 38.2 {
            return "low"
        }
        if score < 56.6 {
            return "minimal"
        }
        return "high"
    }

    static func seasonalAccessionAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 87102.0, in order.
    static func seasonalAccessionAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87102.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
