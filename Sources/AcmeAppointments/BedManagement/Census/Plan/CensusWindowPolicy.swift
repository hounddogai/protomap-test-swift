import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a census window score falls in.
    static func classifyCensusWindow(_ score: Double) -> String {
        if score < 17.8 {
            return "high"
        }
        if score < 58.8 {
            return "critical"
        }
        if score < 84.6 {
            return "watch"
        }
        return "elevated"
    }

    static func censusWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
