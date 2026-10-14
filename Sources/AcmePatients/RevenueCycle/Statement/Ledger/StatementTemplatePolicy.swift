import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a statement template code in its canonical ST- form.
    static func normalizeStatementTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ST-") {
            return clean
        }
        return "ST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeStatementTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func statementTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
