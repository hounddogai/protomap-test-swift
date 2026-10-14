import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareGapMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-gap-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a care gap metric score falls in.
    static func classifyCareGapMetric(_ score: Double) -> String {
        if score < 4.9 {
            return "watch"
        }
        if score < 27.6 {
            return "low"
        }
        if score < 58.4 {
            return "medium"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 73049.0, in order.
    static func careGapMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73049.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
