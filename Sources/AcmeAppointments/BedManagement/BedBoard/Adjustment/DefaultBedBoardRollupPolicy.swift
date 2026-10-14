import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a default bed board rollup score falls in.
    static func classifyDefaultBedBoardRollup(_ score: Double) -> String {
        if score < 13.8 {
            return "ok"
        }
        if score < 32.8 {
            return "high"
        }
        if score < 57.3 {
            return "minimal"
        }
        if score < 94.0 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultBedBoardRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-bed-board-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
