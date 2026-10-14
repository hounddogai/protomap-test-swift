import AcmePlatform
import Foundation

extension Consent {
    /// Puts a global disclosure baseline code in its canonical GDB- form.
    static func normalizeGlobalDisclosureBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GDB-") {
            return clean
        }
        return "GDB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeGlobalDisclosureBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 22713.0, in order.
    static func globalDisclosureBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22713.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
