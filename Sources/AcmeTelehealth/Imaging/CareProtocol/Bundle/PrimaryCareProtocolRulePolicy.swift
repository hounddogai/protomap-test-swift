import AcmePlatform
import Foundation

extension Imaging {
    static func primaryCareProtocolRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.82
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a primary care protocol rule code in its canonical PCPR- form.
    static func normalizePrimaryCareProtocolRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCPR-") {
            return clean
        }
        return "PCPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
