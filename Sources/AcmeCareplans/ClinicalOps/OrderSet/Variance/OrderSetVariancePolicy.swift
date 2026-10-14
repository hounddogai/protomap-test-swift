import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 29983.0, in order.
    static func orderSetVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29983.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a order set variance code in its canonical OSV- form.
    static func normalizeOrderSetVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSV-") {
            return clean
        }
        return "OSV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
