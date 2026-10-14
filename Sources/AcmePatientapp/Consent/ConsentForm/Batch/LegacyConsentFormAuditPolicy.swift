import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a legacy consent form audit score falls in.
    static func classifyLegacyConsentFormAudit(_ score: Double) -> String {
        if score < 4.3 {
            return "high"
        }
        if score < 50.6 {
            return "ok"
        }
        if score < 62.3 {
            return "critical"
        }
        if score < 79.2 {
            return "watch"
        }
        return "low"
    }

    /// Puts a legacy consent form audit code in its canonical LCFA- form.
    static func normalizeLegacyConsentFormAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCFA-") {
            return clean
        }
        return "LCFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 2972.0, in order.
    static func legacyConsentFormAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2972.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
