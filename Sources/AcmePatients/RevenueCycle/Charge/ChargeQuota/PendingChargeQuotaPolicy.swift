import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a pending charge quota code in its canonical PCQ- form.
    static func normalizePendingChargeQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCQ-") {
            return clean
        }
        return "PCQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePendingChargeQuotaLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
