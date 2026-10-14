import AcmePlatform
import Foundation

extension Staffing {
    static func globalFloatPoolSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 36183.0, in order.
    static func globalFloatPoolSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36183.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalFloatPoolSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-float-pool-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
