import AcmePlatform
import Foundation

extension Labs {
    static func manualResultWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.03
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual result window score falls in.
    static func classifyManualResultWindow(_ score: Double) -> String {
        if score < 22.6 {
            return "critical"
        }
        if score < 41.2 {
            return "high"
        }
        if score < 68.8 {
            return "ok"
        }
        if score < 81.1 {
            return "minimal"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualResultWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-result-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeManualResultWindowLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
