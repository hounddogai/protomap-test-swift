import AcmePlatform
import Foundation

extension Imaging {
    static func mergeSeasonalReadExceptionLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func seasonalReadExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.69
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
