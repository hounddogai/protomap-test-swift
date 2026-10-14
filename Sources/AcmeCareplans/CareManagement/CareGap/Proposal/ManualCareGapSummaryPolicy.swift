import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a manual care gap summary score falls in.
    static func classifyManualCareGapSummary(_ score: Double) -> String {
        if score < 15.5 {
            return "critical"
        }
        if score < 24.2 {
            return "watch"
        }
        if score < 82.4 {
            return "elevated"
        }
        return "medium"
    }

    static func manualCareGapSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 20147.0, in order.
    static func manualCareGapSummaryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20147.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualCareGapSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-care-gap-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
