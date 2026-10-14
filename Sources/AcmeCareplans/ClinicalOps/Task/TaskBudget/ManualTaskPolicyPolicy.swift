import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a manual task policy code in its canonical MTP- form.
    static func normalizeManualTaskPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MTP-") {
            return clean
        }
        return "MTP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualTaskPolicyBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
