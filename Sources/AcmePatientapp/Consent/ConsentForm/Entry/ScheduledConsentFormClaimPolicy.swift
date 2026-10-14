import AcmePlatform
import Foundation

extension Consent {
    /// Puts a scheduled consent form claim code in its canonical SCFC- form.
    static func normalizeScheduledConsentFormClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCFC-") {
            return clean
        }
        return "SCFC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledConsentFormClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeScheduledConsentFormClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
