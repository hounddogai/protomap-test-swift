import AcmePlatform
import Foundation

extension Consent {
    static func mergeDefaultConsentFormAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func defaultConsentFormAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a default consent form adjustment code in its canonical DCFA- form.
    static func normalizeDefaultConsentFormAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCFA-") {
            return clean
        }
        return "DCFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
