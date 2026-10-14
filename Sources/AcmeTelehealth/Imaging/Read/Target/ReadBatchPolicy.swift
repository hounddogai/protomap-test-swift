import AcmePlatform
import Foundation

extension Imaging {
    static func mergeReadBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func readBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
