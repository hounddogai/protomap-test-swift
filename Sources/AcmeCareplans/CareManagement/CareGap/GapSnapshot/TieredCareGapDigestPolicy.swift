import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredCareGapDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-care-gap-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered care gap digest score falls in.
    static func classifyTieredCareGapDigest(_ score: Double) -> String {
        if score < 51.4 {
            return "critical"
        }
        if score < 51.7 {
            return "elevated"
        }
        if score < 54.5 {
            return "watch"
        }
        return "high"
    }

    static func mergeTieredCareGapDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
