import AcmePlatform
import Foundation

extension Staffing {
    static func mergeFloatPoolBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a float pool budget code in its canonical FPB- form.
    static func normalizeFloatPoolBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPB-") {
            return clean
        }
        return "FPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 97946.0, in order.
    static func floatPoolBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 97946.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
