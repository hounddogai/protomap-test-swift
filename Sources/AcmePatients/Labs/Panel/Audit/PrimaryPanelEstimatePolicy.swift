import AcmePlatform
import Foundation

extension Labs {
    static func mergePrimaryPanelEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 31107.0, in order.
    static func primaryPanelEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 31107.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a primary panel estimate code in its canonical PPE- form.
    static func normalizePrimaryPanelEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PPE-") {
            return clean
        }
        return "PPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
