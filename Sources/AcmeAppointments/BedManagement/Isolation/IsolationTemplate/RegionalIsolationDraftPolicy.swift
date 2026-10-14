import AcmePlatform
import Foundation

extension BedManagement {
    static func regionalIsolationDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalIsolationDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-isolation-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeRegionalIsolationDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a regional isolation draft score falls in.
    static func classifyRegionalIsolationDraft(_ score: Double) -> String {
        if score < 46.3 {
            return "minimal"
        }
        if score < 92.5 {
            return "high"
        }
        if score < 98.1 {
            return "watch"
        }
        return "elevated"
    }
}
