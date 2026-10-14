import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a assessment agreement score falls in.
    static func classifyAssessmentAgreement(_ score: Double) -> String {
        if score < 23.2 {
            return "minimal"
        }
        if score < 56.5 {
            return "elevated"
        }
        if score < 59.3 {
            return "ok"
        }
        return "watch"
    }

    static func mergeAssessmentAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func assessmentAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
