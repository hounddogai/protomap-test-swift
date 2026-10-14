import AcmePlatform
import Foundation

extension Consent {
    static func mergeConsentFormAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a consent form adjustment score falls in.
    static func classifyConsentFormAdjustment(_ score: Double) -> String {
        if score < 20.8 {
            return "elevated"
        }
        if score < 83.2 {
            return "watch"
        }
        return "critical"
    }
}
