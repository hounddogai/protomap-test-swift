import AcmePlatform
import Foundation

extension Referrals {
    static func strictFollowUpTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a strict follow up template code in its canonical SFUT- form.
    static func normalizeStrictFollowUpTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFUT-") {
            return clean
        }
        return "SFUT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
