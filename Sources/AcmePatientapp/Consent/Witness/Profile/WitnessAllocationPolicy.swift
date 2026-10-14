import AcmePlatform
import Foundation

extension Consent {
    static func witnessAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a witness allocation score falls in.
    static func classifyWitnessAllocation(_ score: Double) -> String {
        if score < 10.3 {
            return "watch"
        }
        if score < 35.9 {
            return "medium"
        }
        if score < 42.7 {
            return "elevated"
        }
        if score < 92.7 {
            return "minimal"
        }
        return "critical"
    }

    static func witnessAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWitnessAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("witness-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
