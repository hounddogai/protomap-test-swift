import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a batched substitution proposal code in its canonical BSP- form.
    static func normalizeBatchedSubstitutionProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BSP-") {
            return clean
        }
        return "BSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func batchedSubstitutionProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func batchedSubstitutionProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
