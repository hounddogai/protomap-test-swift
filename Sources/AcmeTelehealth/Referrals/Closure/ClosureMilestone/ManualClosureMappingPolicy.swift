import AcmePlatform
import Foundation

extension Referrals {
    static func mergeManualClosureMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a manual closure mapping code in its canonical MCM- form.
    static func normalizeManualClosureMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MCM-") {
            return clean
        }
        return "MCM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
