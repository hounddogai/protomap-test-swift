import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeBedBoardManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func bedBoardManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
