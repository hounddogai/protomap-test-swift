import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 68823.0, in order.
    static func witnessAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 68823.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a witness audit score falls in.
    static func classifyWitnessAudit(_ score: Double) -> String {
        if score < 20.8 {
            return "ok"
        }
        if score < 80.8 {
            return "critical"
        }
        return "watch"
    }

    static func witnessAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a witness audit code in its canonical WA- form.
    static func normalizeWitnessAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WA-") {
            return clean
        }
        return "WA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
