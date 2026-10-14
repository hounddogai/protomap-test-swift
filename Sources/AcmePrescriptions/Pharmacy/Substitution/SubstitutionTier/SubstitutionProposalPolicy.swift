import AcmePlatform
import Foundation

extension Pharmacy {
    static func substitutionProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a substitution proposal code in its canonical SP- form.
    static func normalizeSubstitutionProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SP-") {
            return clean
        }
        return "SP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func substitutionProposalWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
