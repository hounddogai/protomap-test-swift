import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a global slot estimate code in its canonical GSE- form.
    static func normalizeGlobalSlotEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSE-") {
            return clean
        }
        return "GSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeGlobalSlotEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
