import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeTieredIsolationTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 96308.0, in order.
    static func tieredIsolationTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96308.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered isolation template code in its canonical TIT- form.
    static func normalizeTieredIsolationTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TIT-") {
            return clean
        }
        return "TIT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
