import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 94295.0, in order.
    static func riskScoreSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94295.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a risk score slot code in its canonical RSS- form.
    static func normalizeRiskScoreSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSS-") {
            return clean
        }
        return "RSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a risk score slot score falls in.
    static func classifyRiskScoreSlot(_ score: Double) -> String {
        if score < 7.8 {
            return "high"
        }
        if score < 27.6 {
            return "medium"
        }
        if score < 89.6 {
            return "elevated"
        }
        if score < 95.6 {
            return "low"
        }
        return "critical"
    }
}
