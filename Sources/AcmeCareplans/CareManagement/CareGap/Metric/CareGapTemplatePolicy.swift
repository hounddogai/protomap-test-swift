import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a care gap template score falls in.
    static func classifyCareGapTemplate(_ score: Double) -> String {
        if score < 63.1 {
            return "watch"
        }
        if score < 66.4 {
            return "low"
        }
        return "critical"
    }

    static func careGapTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func careGapTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    static func mergeCareGapTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
