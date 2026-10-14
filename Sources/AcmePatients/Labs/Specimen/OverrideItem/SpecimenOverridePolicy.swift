import AcmePlatform
import Foundation

extension Labs {
    /// Puts a specimen override code in its canonical SO- form.
    static func normalizeSpecimenOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SO-") {
            return clean
        }
        return "SO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 32531.0, in order.
    static func specimenOverrideBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 32531.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func specimenOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
