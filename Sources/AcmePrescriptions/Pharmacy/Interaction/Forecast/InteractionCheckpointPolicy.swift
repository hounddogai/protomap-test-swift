import AcmePlatform
import Foundation

extension Pharmacy {
    static func interactionCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func interactionCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a interaction checkpoint score falls in.
    static func classifyInteractionCheckpoint(_ score: Double) -> String {
        if score < 19.9 {
            return "watch"
        }
        if score < 51.4 {
            return "minimal"
        }
        if score < 67.9 {
            return "low"
        }
        if score < 80.2 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
