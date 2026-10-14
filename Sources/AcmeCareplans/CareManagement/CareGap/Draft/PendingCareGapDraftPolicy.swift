import AcmePlatform
import Foundation

extension CareManagement {
    static func mergePendingCareGapDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func pendingCareGapDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.59
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a pending care gap draft score falls in.
    static func classifyPendingCareGapDraft(_ score: Double) -> String {
        if score < 32.4 {
            return "minimal"
        }
        if score < 73.7 {
            return "critical"
        }
        return "elevated"
    }
}
