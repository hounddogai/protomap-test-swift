import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 46413.0, in order.
    static func fallbackSkillMixTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 46413.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a fallback skill mix template code in its canonical FSMT- form.
    static func normalizeFallbackSkillMixTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FSMT-") {
            return clean
        }
        return "FSMT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
