import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 60527.0, in order.
    static func strictWorklistClaimBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60527.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeStrictWorklistClaimLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a strict worklist claim code in its canonical SWC- form.
    static func normalizeStrictWorklistClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWC-") {
            return clean
        }
        return "SWC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
