import AcmePlatform
import Foundation

extension Consent {
    /// Puts a disclosure tier code in its canonical DT- form.
    static func normalizeDisclosureTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DT-") {
            return clean
        }
        return "DT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a disclosure tier score falls in.
    static func classifyDisclosureTier(_ score: Double) -> String {
        if score < 14.9 {
            return "medium"
        }
        if score < 50.4 {
            return "elevated"
        }
        if score < 51.4 {
            return "high"
        }
        if score < 59.0 {
            return "minimal"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 11203.0, in order.
    static func disclosureTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11203.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
