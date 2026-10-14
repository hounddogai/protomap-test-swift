import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeStrictRemittanceEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a strict remittance estimate code in its canonical SRE- form.
    static func normalizeStrictRemittanceEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRE-") {
            return clean
        }
        return "SRE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
