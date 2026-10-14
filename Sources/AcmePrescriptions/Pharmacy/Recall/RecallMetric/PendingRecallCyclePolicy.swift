import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergePendingRecallCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a pending recall cycle score falls in.
    static func classifyPendingRecallCycle(_ score: Double) -> String {
        if score < 29.6 {
            return "minimal"
        }
        if score < 58.8 {
            return "watch"
        }
        if score < 89.4 {
            return "ok"
        }
        if score < 96.2 {
            return "high"
        }
        return "medium"
    }
}
