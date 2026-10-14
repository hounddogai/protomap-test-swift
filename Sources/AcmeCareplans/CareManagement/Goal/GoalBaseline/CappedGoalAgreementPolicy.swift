import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeCappedGoalAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a capped goal agreement code in its canonical CGA- form.
    static func normalizeCappedGoalAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGA-") {
            return clean
        }
        return "CGA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
