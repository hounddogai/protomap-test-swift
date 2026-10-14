import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 83465.0, in order.
    static func worklistMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 83465.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWorklistMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("worklist-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a worklist milestone score falls in.
    static func classifyWorklistMilestone(_ score: Double) -> String {
        if score < 36.7 {
            return "elevated"
        }
        if score < 56.0 {
            return "watch"
        }
        return "ok"
    }

    static func worklistMilestoneWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.63
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
