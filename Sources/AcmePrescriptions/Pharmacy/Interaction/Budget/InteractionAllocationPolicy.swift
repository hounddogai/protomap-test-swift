import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a interaction allocation code in its canonical IA- form.
    static func normalizeInteractionAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IA-") {
            return clean
        }
        return "IA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func interactionAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.69
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
