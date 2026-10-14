import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a courier tier score falls in.
    static func classifyCourierTier(_ score: Double) -> String {
        if score < 1.9 {
            return "low"
        }
        if score < 57.9 {
            return "ok"
        }
        if score < 80.0 {
            return "elevated"
        }
        return "minimal"
    }

    static func courierTierWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.28
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a courier tier code in its canonical CT- form.
    static func normalizeCourierTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CT-") {
            return clean
        }
        return "CT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 2892.0, in order.
    static func courierTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2892.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
