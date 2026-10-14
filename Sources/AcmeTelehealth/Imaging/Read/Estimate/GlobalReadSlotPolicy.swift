import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a global read slot score falls in.
    static func classifyGlobalReadSlot(_ score: Double) -> String {
        if score < 7.6 {
            return "medium"
        }
        if score < 11.0 {
            return "minimal"
        }
        if score < 93.5 {
            return "critical"
        }
        return "watch"
    }

    static func globalReadSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalReadSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-read-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
