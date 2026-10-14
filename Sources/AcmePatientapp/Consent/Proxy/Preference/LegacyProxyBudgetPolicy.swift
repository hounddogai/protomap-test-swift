import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 12660.0, in order.
    static func legacyProxyBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12660.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeLegacyProxyBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy proxy budget code in its canonical LPB- form.
    static func normalizeLegacyProxyBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LPB-") {
            return clean
        }
        return "LPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
