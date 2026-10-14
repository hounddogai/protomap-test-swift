import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a order set tier score falls in.
    static func classifyOrderSetTier(_ score: Double) -> String {
        if score < 24.1 {
            return "minimal"
        }
        if score < 48.9 {
            return "ok"
        }
        if score < 91.2 {
            return "elevated"
        }
        return "critical"
    }

    static func mergeOrderSetTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeOrderSetTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("order-set-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
