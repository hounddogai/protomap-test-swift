import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a seasonal order set template code in its canonical SOST- form.
    static func normalizeSeasonalOrderSetTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOST-") {
            return clean
        }
        return "SOST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalOrderSetTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 95448.0, in order.
    static func seasonalOrderSetTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95448.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
