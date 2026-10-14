import AcmePlatform
import Foundation

extension ClinicalOps {
    static func rollingAlertForecastBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a rolling alert forecast score falls in.
    static func classifyRollingAlertForecast(_ score: Double) -> String {
        if score < 5.9 {
            return "high"
        }
        if score < 12.4 {
            return "low"
        }
        if score < 36.5 {
            return "medium"
        }
        return "critical"
    }

    /// Puts a rolling alert forecast code in its canonical RAF- form.
    static func normalizeRollingAlertForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAF-") {
            return clean
        }
        return "RAF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 50786.0, in order.
    static func rollingAlertForecastBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50786.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
