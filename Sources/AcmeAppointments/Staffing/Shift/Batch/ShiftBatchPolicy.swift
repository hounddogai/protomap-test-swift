import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a shift batch score falls in.
    static func classifyShiftBatch(_ score: Double) -> String {
        if score < 24.6 {
            return "medium"
        }
        if score < 69.5 {
            return "watch"
        }
        if score < 88.1 {
            return "minimal"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeShiftBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("shift-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
