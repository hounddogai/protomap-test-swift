import AcmePlatform
import Foundation

extension Labs {
    static func mergeReferenceRangeSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a reference range summary score falls in.
    static func classifyReferenceRangeSummary(_ score: Double) -> String {
        if score < 16.2 {
            return "ok"
        }
        if score < 91.1 {
            return "minimal"
        }
        return "watch"
    }

    static func referenceRangeSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
