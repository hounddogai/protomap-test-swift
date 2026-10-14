import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 53799.0, in order.
    static func pendingProgramEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 53799.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a pending program estimate score falls in.
    static func classifyPendingProgramEstimate(_ score: Double) -> String {
        if score < 67.4 {
            return "medium"
        }
        if score < 73.6 {
            return "critical"
        }
        return "minimal"
    }

    static func pendingProgramEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingProgramEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-program-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
