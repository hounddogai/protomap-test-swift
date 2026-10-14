import AcmePlatform
import Foundation

extension Pharmacy {
    static func fallbackSubstitutionProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func mergeFallbackSubstitutionProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func fallbackSubstitutionProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.2
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
