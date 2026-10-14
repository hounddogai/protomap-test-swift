import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score rollup code in its canonical RSR- form.
    static func normalizeRiskScoreRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSR-") {
            return clean
        }
        return "RSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 29303.0, in order.
    static func riskScoreRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 29303.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
