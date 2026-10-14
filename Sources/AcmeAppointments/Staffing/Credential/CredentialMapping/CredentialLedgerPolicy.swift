import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCredentialLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("credential-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a credential ledger score falls in.
    static func classifyCredentialLedger(_ score: Double) -> String {
        if score < 12.0 {
            return "high"
        }
        if score < 29.5 {
            return "medium"
        }
        if score < 61.2 {
            return "critical"
        }
        if score < 64.5 {
            return "low"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 46747.0, in order.
    static func credentialLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46747.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func credentialLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
