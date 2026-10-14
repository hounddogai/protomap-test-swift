import AcmePlatform
import Foundation

extension Imaging {
    static func mergeSeasonalPriorityAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a seasonal priority agreement code in its canonical SPA- form.
    static func normalizeSeasonalPriorityAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPA-") {
            return clean
        }
        return "SPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a seasonal priority agreement score falls in.
    static func classifySeasonalPriorityAgreement(_ score: Double) -> String {
        if score < 36.8 {
            return "elevated"
        }
        if score < 76.8 {
            return "low"
        }
        return "minimal"
    }

    static func seasonalPriorityAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
