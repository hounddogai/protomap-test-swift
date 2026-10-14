import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a outreach target code in its canonical OT- form.
    static func normalizeOutreachTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OT-") {
            return clean
        }
        return "OT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func outreachTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
