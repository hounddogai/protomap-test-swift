import AcmePlatform
import Foundation

extension Consent {
    static func revocationTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.69
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 99491.0, in order.
    static func revocationTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99491.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a revocation template score falls in.
    static func classifyRevocationTemplate(_ score: Double) -> String {
        if score < 8.7 {
            return "critical"
        }
        if score < 58.3 {
            return "watch"
        }
        if score < 94.4 {
            return "high"
        }
        return "medium"
    }
}
