import AcmePlatform
import Foundation

extension Imaging {
    static func mergeGlobalWorklistOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a global worklist override score falls in.
    static func classifyGlobalWorklistOverride(_ score: Double) -> String {
        if score < 13.0 {
            return "medium"
        }
        if score < 32.4 {
            return "high"
        }
        if score < 37.9 {
            return "elevated"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalWorklistOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-worklist-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
