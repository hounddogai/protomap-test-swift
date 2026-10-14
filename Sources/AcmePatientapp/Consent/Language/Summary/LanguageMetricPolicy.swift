import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 14568.0, in order.
    static func languageMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14568.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func languageMetricBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a language metric code in its canonical LM- form.
    static func normalizeLanguageMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LM-") {
            return clean
        }
        return "LM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
