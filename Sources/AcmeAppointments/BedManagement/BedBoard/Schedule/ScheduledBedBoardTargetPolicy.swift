import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledBedBoardTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-bed-board-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func scheduledBedBoardTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled bed board target score falls in.
    static func classifyScheduledBedBoardTarget(_ score: Double) -> String {
        if score < 16.6 {
            return "elevated"
        }
        if score < 72.1 {
            return "low"
        }
        return "high"
    }
}
