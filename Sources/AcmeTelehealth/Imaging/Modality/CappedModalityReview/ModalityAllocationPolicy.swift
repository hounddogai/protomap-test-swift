import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalityAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func modalityAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a modality allocation score falls in.
    static func classifyModalityAllocation(_ score: Double) -> String {
        if score < 3.9 {
            return "watch"
        }
        if score < 54.2 {
            return "elevated"
        }
        return "high"
    }
}
