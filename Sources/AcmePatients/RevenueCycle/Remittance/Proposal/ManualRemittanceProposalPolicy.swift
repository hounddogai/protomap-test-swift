import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a manual remittance proposal score falls in.
    static func classifyManualRemittanceProposal(_ score: Double) -> String {
        if score < 13.8 {
            return "minimal"
        }
        if score < 17.6 {
            return "watch"
        }
        if score < 47.4 {
            return "elevated"
        }
        if score < 67.0 {
            return "medium"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualRemittanceProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-remittance-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 21646.0, in order.
    static func manualRemittanceProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 21646.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualRemittanceProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.52
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
