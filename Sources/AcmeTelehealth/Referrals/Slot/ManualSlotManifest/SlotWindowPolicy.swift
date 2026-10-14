import AcmePlatform
import Foundation

extension Referrals {
    static func slotWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a slot window score falls in.
    static func classifySlotWindow(_ score: Double) -> String {
        if score < 64.0 {
            return "watch"
        }
        if score < 74.2 {
            return "elevated"
        }
        return "high"
    }
}
