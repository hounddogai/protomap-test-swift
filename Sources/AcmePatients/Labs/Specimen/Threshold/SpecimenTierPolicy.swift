import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen tier score falls in.
    static func classifySpecimenTier(_ score: Double) -> String {
        if score < 26.3 {
            return "low"
        }
        if score < 32.7 {
            return "watch"
        }
        if score < 97.2 {
            return "elevated"
        }
        return "medium"
    }

    static func specimenTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func mergeSpecimenTierLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
