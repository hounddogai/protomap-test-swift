import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a result slot score falls in.
    static func classifyResultSlot(_ score: Double) -> String {
        if score < 19.6 {
            return "high"
        }
        if score < 36.0 {
            return "ok"
        }
        if score < 40.5 {
            return "elevated"
        }
        if score < 78.2 {
            return "medium"
        }
        return "critical"
    }

    static func resultSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
