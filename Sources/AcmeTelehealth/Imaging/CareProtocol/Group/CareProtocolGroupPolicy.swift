import AcmePlatform
import Foundation

extension Imaging {
    static func mergeCareProtocolGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func careProtocolGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a care protocol group score falls in.
    static func classifyCareProtocolGroup(_ score: Double) -> String {
        if score < 5.9 {
            return "medium"
        }
        if score < 89.0 {
            return "minimal"
        }
        return "elevated"
    }
}
