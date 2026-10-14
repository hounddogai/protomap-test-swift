import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a manual consent form proposal score falls in.
    static func classifyManualConsentFormProposal(_ score: Double) -> String {
        if score < 7.2 {
            return "elevated"
        }
        if score < 23.3 {
            return "high"
        }
        if score < 40.6 {
            return "watch"
        }
        if score < 73.7 {
            return "critical"
        }
        return "minimal"
    }

    static func manualConsentFormProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 84509.0, in order.
    static func manualConsentFormProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84509.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualConsentFormProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
