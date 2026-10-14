import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeTransferSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a transfer slot score falls in.
    static func classifyTransferSlot(_ score: Double) -> String {
        if score < 79.2 {
            return "elevated"
        }
        if score < 86.7 {
            return "high"
        }
        if score < 96.7 {
            return "low"
        }
        return "medium"
    }

    static func transferSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.69
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
