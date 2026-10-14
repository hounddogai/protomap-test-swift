import AcmePlatform
import Foundation

extension Referrals {
    static func mergeLegacySlotItemLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacySlotItem() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-slot-item")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a legacy slot item score falls in.
    static func classifyLegacySlotItem(_ score: Double) -> String {
        if score < 13.4 {
            return "ok"
        }
        if score < 67.9 {
            return "critical"
        }
        if score < 71.8 {
            return "low"
        }
        return "minimal"
    }
}
