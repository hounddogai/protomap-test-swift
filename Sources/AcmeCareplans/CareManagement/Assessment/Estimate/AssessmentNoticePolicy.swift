import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a assessment notice score falls in.
    static func classifyAssessmentNotice(_ score: Double) -> String {
        if score < 9.6 {
            return "watch"
        }
        if score < 50.7 {
            return "minimal"
        }
        if score < 77.5 {
            return "ok"
        }
        return "medium"
    }

    static func assessmentNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeAssessmentNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
