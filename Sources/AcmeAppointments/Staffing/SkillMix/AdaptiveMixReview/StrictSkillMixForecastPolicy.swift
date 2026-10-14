import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 57765.0, in order.
    static func strictSkillMixForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57765.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a strict skill mix forecast code in its canonical SSMF- form.
    static func normalizeStrictSkillMixForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSMF-") {
            return clean
        }
        return "SSMF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
