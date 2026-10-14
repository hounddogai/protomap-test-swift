import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeManualCareProtocolNoticeLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a manual care protocol notice code in its canonical MCPN- form.
    static func normalizeManualCareProtocolNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCPN-") {
            return clean
        }
        return "MCPN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
