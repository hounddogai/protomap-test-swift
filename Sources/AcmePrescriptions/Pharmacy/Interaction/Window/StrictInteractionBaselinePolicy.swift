import AcmePlatform
import Foundation

extension Pharmacy {
    static func strictInteractionBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func mergeStrictInteractionBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictInteractionBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
