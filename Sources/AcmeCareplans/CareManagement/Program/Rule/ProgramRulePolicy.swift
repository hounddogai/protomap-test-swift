import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a program rule code in its canonical PR- form.
    static func normalizeProgramRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PR-") {
            return clean
        }
        return "PR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeProgramRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
