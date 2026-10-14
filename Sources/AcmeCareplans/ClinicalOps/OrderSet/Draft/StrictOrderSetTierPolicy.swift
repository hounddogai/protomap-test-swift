import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 61838.0, in order.
    static func strictOrderSetTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 61838.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a strict order set tier score falls in.
    static func classifyStrictOrderSetTier(_ score: Double) -> String {
        if score < 1.4 {
            return "medium"
        }
        if score < 10.8 {
            return "low"
        }
        if score < 77.7 {
            return "watch"
        }
        if score < 84.0 {
            return "ok"
        }
        return "critical"
    }

    /// Puts a strict order set tier code in its canonical SOST- form.
    static func normalizeStrictOrderSetTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOST-") {
            return clean
        }
        return "SOST-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictOrderSetTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
