import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 21206.0, in order.
    static func formularySlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 21206.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a formulary slot code in its canonical FS- form.
    static func normalizeFormularySlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FS-") {
            return clean
        }
        return "FS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func formularySlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a formulary slot score falls in.
    static func classifyFormularySlot(_ score: Double) -> String {
        if score < 12.8 {
            return "elevated"
        }
        if score < 32.2 {
            return "watch"
        }
        if score < 34.4 {
            return "medium"
        }
        return "high"
    }
}
