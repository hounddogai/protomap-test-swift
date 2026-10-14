import AcmePlatform
import Foundation

extension BedManagement {
    static func defaultCensusWindowBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func defaultCensusWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultCensusWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-census-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default census window score falls in.
    static func classifyDefaultCensusWindow(_ score: Double) -> String {
        if score < 4.7 {
            return "ok"
        }
        if score < 5.5 {
            return "critical"
        }
        if score < 36.8 {
            return "low"
        }
        if score < 67.1 {
            return "minimal"
        }
        return "elevated"
    }
}
