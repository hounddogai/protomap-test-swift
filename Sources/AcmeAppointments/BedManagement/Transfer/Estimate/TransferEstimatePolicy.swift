import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTransferEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("transfer-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a transfer estimate score falls in.
    static func classifyTransferEstimate(_ score: Double) -> String {
        if score < 55.6 {
            return "critical"
        }
        if score < 71.5 {
            return "minimal"
        }
        return "watch"
    }

    static func mergeTransferEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
