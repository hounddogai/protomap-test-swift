import AcmePlatform
import Foundation

extension Imaging {
    static func scheduledCareProtocolMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a scheduled care protocol mapping code in its canonical SCPM- form.
    static func normalizeScheduledCareProtocolMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCPM-") {
            return clean
        }
        return "SCPM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
