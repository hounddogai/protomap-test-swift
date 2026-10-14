import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func roundingSnapshotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a rounding snapshot score falls in.
    static func classifyRoundingSnapshot(_ score: Double) -> String {
        if score < 31.7 {
            return "ok"
        }
        if score < 67.7 {
            return "minimal"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 39068.0, in order.
    static func roundingSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39068.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
