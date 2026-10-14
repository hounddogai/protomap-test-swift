import AcmePlatform
import Foundation

extension Imaging {
    static func scheduledCareProtocolExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a scheduled care protocol exception score falls in.
    static func classifyScheduledCareProtocolException(_ score: Double) -> String {
        if score < 38.4 {
            return "ok"
        }
        if score < 64.6 {
            return "watch"
        }
        return "critical"
    }

    static func mergeScheduledCareProtocolExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func scheduledCareProtocolExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
