import AcmePlatform
import Foundation

extension Pharmacy {
    static func legacyRecallTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a legacy recall template code in its canonical LRT- form.
    static func normalizeLegacyRecallTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRT-") {
            return clean
        }
        return "LRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
