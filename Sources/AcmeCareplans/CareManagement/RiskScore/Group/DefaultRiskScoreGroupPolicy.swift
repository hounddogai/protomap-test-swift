import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a default risk score group score falls in.
    static func classifyDefaultRiskScoreGroup(_ score: Double) -> String {
        if score < 6.6 {
            return "medium"
        }
        if score < 24.1 {
            return "low"
        }
        if score < 36.5 {
            return "watch"
        }
        if score < 74.0 {
            return "elevated"
        }
        return "minimal"
    }

    /// Puts a default risk score group code in its canonical DRSG- form.
    static func normalizeDefaultRiskScoreGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRSG-") {
            return clean
        }
        return "DRSG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 57645.0, in order.
    static func defaultRiskScoreGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57645.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
