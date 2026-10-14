import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form score score falls in.
    static func classifyConsentFormScore(_ score: Double) -> String {
        if score < 4.4 {
            return "medium"
        }
        if score < 33.3 {
            return "high"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 69372.0, in order.
    static func consentFormScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69372.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a consent form score code in its canonical CFS- form.
    static func normalizeConsentFormScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFS-") {
            return clean
        }
        return "CFS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
