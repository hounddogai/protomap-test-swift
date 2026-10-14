import AcmePlatform
import Foundation

extension Referrals {
    static func primaryEligibilityQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a primary eligibility quota code in its canonical PEQ- form.
    static func normalizePrimaryEligibilityQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PEQ-") {
            return clean
        }
        return "PEQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
