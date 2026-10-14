import AcmePlatform
import Foundation

extension Labs {
    /// Puts a scheduled specimen tier code in its canonical SST- form.
    static func normalizeScheduledSpecimenTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SST-") {
            return clean
        }
        return "SST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a scheduled specimen tier score falls in.
    static func classifyScheduledSpecimenTier(_ score: Double) -> String {
        if score < 4.5 {
            return "high"
        }
        if score < 30.6 {
            return "elevated"
        }
        return "ok"
    }

    /// Counts how many amounts fit in a budget of 227.0, in order.
    static func scheduledSpecimenTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 227.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
