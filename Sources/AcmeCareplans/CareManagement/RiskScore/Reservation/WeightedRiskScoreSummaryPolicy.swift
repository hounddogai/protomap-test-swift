import AcmePlatform
import Foundation

extension CareManagement {
    static func weightedRiskScoreSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedRiskScoreSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-risk-score-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 92225.0, in order.
    static func weightedRiskScoreSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92225.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
