import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a strict bed board checkpoint score falls in.
    static func classifyStrictBedBoardCheckpoint(_ score: Double) -> String {
        if score < 41.1 {
            return "ok"
        }
        if score < 66.3 {
            return "high"
        }
        if score < 97.2 {
            return "medium"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictBedBoardCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-bed-board-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
