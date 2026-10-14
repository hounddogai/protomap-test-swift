import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a fallback acuity plan request code in its canonical FAPR- form.
    static func normalizeFallbackAcuityPlanRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FAPR-") {
            return clean
        }
        return "FAPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func fallbackAcuityPlanRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.14
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
