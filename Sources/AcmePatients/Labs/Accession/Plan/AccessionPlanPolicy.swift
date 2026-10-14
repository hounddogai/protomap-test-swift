import AcmePlatform
import Foundation

extension Labs {
    /// Puts a accession plan code in its canonical AP- form.
    static func normalizeAccessionPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AP-") {
            return clean
        }
        return "AP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func accessionPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.33
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
