import AcmePlatform
import Foundation

extension Referrals {
    static func slotCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.09
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a slot checkpoint score falls in.
    static func classifySlotCheckpoint(_ score: Double) -> String {
        if score < 22.8 {
            return "high"
        }
        if score < 67.9 {
            return "critical"
        }
        if score < 72.3 {
            return "medium"
        }
        if score < 79.7 {
            return "ok"
        }
        return "low"
    }
}
