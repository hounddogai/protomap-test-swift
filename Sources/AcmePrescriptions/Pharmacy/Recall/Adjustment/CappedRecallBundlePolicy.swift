import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeCappedRecallBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped recall bundle score falls in.
    static func classifyCappedRecallBundle(_ score: Double) -> String {
        if score < 41.5 {
            return "ok"
        }
        if score < 94.6 {
            return "minimal"
        }
        return "medium"
    }

    static func cappedRecallBundleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
