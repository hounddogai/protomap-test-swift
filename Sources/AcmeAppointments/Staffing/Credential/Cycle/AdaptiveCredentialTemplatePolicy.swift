import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 89087.0, in order.
    static func adaptiveCredentialTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89087.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a adaptive credential template code in its canonical ACT- form.
    static func normalizeAdaptiveCredentialTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACT-") {
            return clean
        }
        return "ACT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
