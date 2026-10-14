import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultModalityTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-modality-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func defaultModalityTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func defaultModalityTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a default modality target score falls in.
    static func classifyDefaultModalityTarget(_ score: Double) -> String {
        if score < 33.3 {
            return "high"
        }
        if score < 75.6 {
            return "medium"
        }
        if score < 77.4 {
            return "elevated"
        }
        if score < 93.2 {
            return "ok"
        }
        return "low"
    }
}
