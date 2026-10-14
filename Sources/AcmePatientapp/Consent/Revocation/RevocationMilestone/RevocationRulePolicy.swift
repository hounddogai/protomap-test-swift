import AcmePlatform
import Foundation

extension Consent {
    static func revocationRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 45482.0, in order.
    static func revocationRuleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 45482.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
