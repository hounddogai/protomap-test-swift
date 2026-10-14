import AcmePlatform
import Foundation

extension Imaging {
    static func mergeWeightedStudyForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func weightedStudyForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a weighted study forecast code in its canonical WSF- form.
    static func normalizeWeightedStudyForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WSF-") {
            return clean
        }
        return "WSF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedStudyForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.69
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
