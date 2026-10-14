import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a eligibility template code in its canonical ET- form.
    static func normalizeEligibilityTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ET-") {
            return clean
        }
        return "ET-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func eligibilityTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
