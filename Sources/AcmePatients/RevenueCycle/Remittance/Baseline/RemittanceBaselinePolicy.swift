import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 42152.0, in order.
    static func remittanceBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 42152.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a remittance baseline score falls in.
    static func classifyRemittanceBaseline(_ score: Double) -> String {
        if score < 3.4 {
            return "medium"
        }
        if score < 29.1 {
            return "high"
        }
        if score < 38.6 {
            return "critical"
        }
        if score < 88.6 {
            return "watch"
        }
        return "ok"
    }
}
