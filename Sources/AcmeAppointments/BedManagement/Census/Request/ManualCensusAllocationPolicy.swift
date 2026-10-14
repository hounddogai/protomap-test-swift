import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a manual census allocation score falls in.
    static func classifyManualCensusAllocation(_ score: Double) -> String {
        if score < 27.5 {
            return "low"
        }
        if score < 36.7 {
            return "ok"
        }
        if score < 62.8 {
            return "critical"
        }
        if score < 97.6 {
            return "high"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualCensusAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-census-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func manualCensusAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
