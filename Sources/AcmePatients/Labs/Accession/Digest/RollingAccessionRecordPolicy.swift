import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a rolling accession record score falls in.
    static func classifyRollingAccessionRecord(_ score: Double) -> String {
        if score < 15.3 {
            return "low"
        }
        if score < 25.8 {
            return "watch"
        }
        if score < 58.4 {
            return "minimal"
        }
        if score < 96.3 {
            return "high"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingAccessionRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-accession-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
