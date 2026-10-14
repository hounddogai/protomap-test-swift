import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a order set bundle score falls in.
    static func classifyOrderSetBundle(_ score: Double) -> String {
        if score < 15.2 {
            return "minimal"
        }
        if score < 21.5 {
            return "ok"
        }
        if score < 51.8 {
            return "medium"
        }
        if score < 77.2 {
            return "elevated"
        }
        return "low"
    }

    static func orderSetBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func mergeOrderSetBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
