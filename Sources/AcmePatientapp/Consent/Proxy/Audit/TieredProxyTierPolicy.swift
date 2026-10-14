import AcmePlatform
import Foundation

extension Consent {
    static func mergeTieredProxyTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a tiered proxy tier score falls in.
    static func classifyTieredProxyTier(_ score: Double) -> String {
        if score < 33.0 {
            return "medium"
        }
        if score < 42.4 {
            return "ok"
        }
        if score < 56.7 {
            return "minimal"
        }
        if score < 71.5 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredProxyTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-proxy-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
