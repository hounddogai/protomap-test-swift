import AcmePlatform
import Foundation

extension ClinicalOps {
    static func orderSetCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a order set cycle score falls in.
    static func classifyOrderSetCycle(_ score: Double) -> String {
        if score < 9.2 {
            return "elevated"
        }
        if score < 46.1 {
            return "low"
        }
        if score < 70.6 {
            return "watch"
        }
        if score < 98.9 {
            return "ok"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func orderSetCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
