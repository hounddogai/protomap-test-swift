import AcmePlatform
import Foundation

extension Pharmacy {
    static func globalInventoryWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func globalInventoryWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a global inventory window score falls in.
    static func classifyGlobalInventoryWindow(_ score: Double) -> String {
        if score < 16.9 {
            return "ok"
        }
        if score < 95.0 {
            return "critical"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalInventoryWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-inventory-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
