import AcmePlatform
import Foundation

extension Imaging {
    static func seasonalStudyBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a seasonal study batch score falls in.
    static func classifySeasonalStudyBatch(_ score: Double) -> String {
        if score < 37.8 {
            return "low"
        }
        if score < 48.0 {
            return "minimal"
        }
        if score < 61.2 {
            return "ok"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalStudyBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-study-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
