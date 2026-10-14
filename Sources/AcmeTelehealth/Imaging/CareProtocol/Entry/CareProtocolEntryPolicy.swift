import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a care protocol entry code in its canonical CPE- form.
    static func normalizeCareProtocolEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPE-") {
            return clean
        }
        return "CPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careProtocolEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
