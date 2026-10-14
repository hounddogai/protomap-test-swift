import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a modality profile score falls in.
    static func classifyModalityProfile(_ score: Double) -> String {
        if score < 18.1 {
            return "high"
        }
        if score < 31.2 {
            return "ok"
        }
        if score < 44.4 {
            return "watch"
        }
        if score < 90.2 {
            return "critical"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeModalityProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("modality-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func modalityProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeModalityProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
