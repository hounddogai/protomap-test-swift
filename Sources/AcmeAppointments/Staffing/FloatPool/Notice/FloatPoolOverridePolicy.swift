import AcmePlatform
import Foundation

extension Staffing {
    static func floatPoolOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a float pool override score falls in.
    static func classifyFloatPoolOverride(_ score: Double) -> String {
        if score < 59.7 {
            return "elevated"
        }
        if score < 66.6 {
            return "high"
        }
        return "low"
    }

    static func mergeFloatPoolOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
