import AcmePlatform
import Foundation

extension Consent {
    static func mergePrimaryProxySummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryProxySummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-proxy-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryProxySummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a primary proxy summary score falls in.
    static func classifyPrimaryProxySummary(_ score: Double) -> String {
        if score < 29.4 {
            return "watch"
        }
        if score < 51.1 {
            return "low"
        }
        if score < 96.0 {
            return "ok"
        }
        return "minimal"
    }
}
