import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 99645.0, in order.
    static func scheduledCareGapPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99645.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a scheduled care gap policy code in its canonical SCGP- form.
    static func normalizeScheduledCareGapPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCGP-") {
            return clean
        }
        return "SCGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
