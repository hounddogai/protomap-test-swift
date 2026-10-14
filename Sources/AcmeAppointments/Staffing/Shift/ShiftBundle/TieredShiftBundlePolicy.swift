import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredShiftBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-shift-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered shift bundle score falls in.
    static func classifyTieredShiftBundle(_ score: Double) -> String {
        if score < 26.6 {
            return "medium"
        }
        if score < 42.6 {
            return "minimal"
        }
        if score < 75.5 {
            return "high"
        }
        return "critical"
    }

    static func mergeTieredShiftBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
