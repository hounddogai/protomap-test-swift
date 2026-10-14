import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score adjustment code in its canonical RSA- form.
    static func normalizeRiskScoreAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSA-") {
            return clean
        }
        return "RSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRiskScoreAdjustmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func riskScoreAdjustmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 94129.0, in order.
    static func riskScoreAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94129.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
