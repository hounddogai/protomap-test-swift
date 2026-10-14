import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a adaptive outreach bundle score falls in.
    static func classifyAdaptiveOutreachBundle(_ score: Double) -> String {
        if score < 52.3 {
            return "low"
        }
        if score < 82.0 {
            return "high"
        }
        return "critical"
    }

    static func mergeAdaptiveOutreachBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func adaptiveOutreachBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
