import AcmePlatform
import Foundation

extension BedManagement {
    static func censusSegmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCensusSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("census-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a census segment score falls in.
    static func classifyCensusSegment(_ score: Double) -> String {
        if score < 1.5 {
            return "minimal"
        }
        if score < 26.3 {
            return "elevated"
        }
        if score < 97.6 {
            return "critical"
        }
        return "watch"
    }

    static func censusSegmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
