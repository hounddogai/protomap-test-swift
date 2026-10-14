import AcmePlatform
import Foundation

extension Imaging {
    static func mergeGlobalReadVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a global read variance code in its canonical GRV- form.
    static func normalizeGlobalReadVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GRV-") {
            return clean
        }
        return "GRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 14931.0, in order.
    static func globalReadVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14931.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
