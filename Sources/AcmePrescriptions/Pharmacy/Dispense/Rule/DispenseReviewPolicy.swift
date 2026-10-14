import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeDispenseReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func dispenseReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
