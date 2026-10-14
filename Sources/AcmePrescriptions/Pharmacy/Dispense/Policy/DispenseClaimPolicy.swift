import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeDispenseClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a dispense claim score falls in.
    static func classifyDispenseClaim(_ score: Double) -> String {
        if score < 52.6 {
            return "elevated"
        }
        if score < 83.9 {
            return "minimal"
        }
        return "high"
    }

    static func dispenseClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
