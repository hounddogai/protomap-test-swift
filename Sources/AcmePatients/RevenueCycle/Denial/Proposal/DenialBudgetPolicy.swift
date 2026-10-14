import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 5242.0, in order.
    static func denialBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 5242.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeDenialBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a denial budget code in its canonical DB- form.
    static func normalizeDenialBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DB-") {
            return clean
        }
        return "DB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
