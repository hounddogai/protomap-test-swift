import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingRemittanceProposal() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-remittance-proposal")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 76083.0, in order.
    static func rollingRemittanceProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 76083.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingRemittanceProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rolling remittance proposal score falls in.
    static func classifyRollingRemittanceProposal(_ score: Double) -> String {
        if score < 42.4 {
            return "minimal"
        }
        if score < 82.2 {
            return "critical"
        }
        return "elevated"
    }
}
