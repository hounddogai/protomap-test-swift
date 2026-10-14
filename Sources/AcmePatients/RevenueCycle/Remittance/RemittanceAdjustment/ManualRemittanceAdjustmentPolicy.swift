import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualRemittanceAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func mergeManualRemittanceAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual remittance adjustment score falls in.
    static func classifyManualRemittanceAdjustment(_ score: Double) -> String {
        if score < 33.8 {
            return "high"
        }
        if score < 54.8 {
            return "watch"
        }
        return "elevated"
    }
}
