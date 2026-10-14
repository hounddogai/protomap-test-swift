import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a weighted transfer slot code in its canonical WTS- form.
    static func normalizeWeightedTransferSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WTS-") {
            return clean
        }
        return "WTS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedTransferSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
