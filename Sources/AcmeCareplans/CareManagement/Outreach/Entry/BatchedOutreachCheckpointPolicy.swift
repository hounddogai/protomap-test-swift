import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a batched outreach checkpoint score falls in.
    static func classifyBatchedOutreachCheckpoint(_ score: Double) -> String {
        if score < 9.2 {
            return "low"
        }
        if score < 49.7 {
            return "ok"
        }
        if score < 72.8 {
            return "medium"
        }
        if score < 96.0 {
            return "minimal"
        }
        return "critical"
    }

    static func batchedOutreachCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedOutreachCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-outreach-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
