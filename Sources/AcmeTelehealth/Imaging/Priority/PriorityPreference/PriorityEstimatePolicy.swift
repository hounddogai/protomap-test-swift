import AcmePlatform
import Foundation

extension Imaging {
    static func mergePriorityEstimateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 19580.0, in order.
    static func priorityEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 19580.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a priority estimate code in its canonical PE- form.
    static func normalizePriorityEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PE-") {
            return clean
        }
        return "PE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
