import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeIsolationBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeIsolationBatch() -> Int {
        let policy = Kit.Retry.defaultPolicy("isolation-batch")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a isolation batch score falls in.
    static func classifyIsolationBatch(_ score: Double) -> String {
        if score < 38.1 {
            return "medium"
        }
        if score < 52.8 {
            return "minimal"
        }
        if score < 83.3 {
            return "elevated"
        }
        return "watch"
    }
}
