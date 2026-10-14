import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a primary denial score code in its canonical PDS- form.
    static func normalizePrimaryDenialScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PDS-") {
            return clean
        }
        return "PDS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a primary denial score score falls in.
    static func classifyPrimaryDenialScore(_ score: Double) -> String {
        if score < 7.7 {
            return "watch"
        }
        if score < 23.5 {
            return "low"
        }
        if score < 30.8 {
            return "medium"
        }
        if score < 50.2 {
            return "critical"
        }
        return "elevated"
    }

    /// Counts how many amounts fit in a budget of 84405.0, in order.
    static func primaryDenialScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 84405.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
