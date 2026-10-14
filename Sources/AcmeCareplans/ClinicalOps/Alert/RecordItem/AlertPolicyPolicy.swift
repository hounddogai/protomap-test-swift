import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a alert policy code in its canonical AP- form.
    static func normalizeAlertPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AP-") {
            return clean
        }
        return "AP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 68594.0, in order.
    static func alertPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68594.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
