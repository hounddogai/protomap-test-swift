import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a outreach estimate code in its canonical OE- form.
    static func normalizeOutreachEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OE-") {
            return clean
        }
        return "OE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func outreachEstimateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
