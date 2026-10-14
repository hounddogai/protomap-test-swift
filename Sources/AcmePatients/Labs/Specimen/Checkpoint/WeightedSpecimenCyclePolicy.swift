import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 6258.0, in order.
    static func weightedSpecimenCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6258.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted specimen cycle code in its canonical WSC- form.
    static func normalizeWeightedSpecimenCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WSC-") {
            return clean
        }
        return "WSC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a weighted specimen cycle score falls in.
    static func classifyWeightedSpecimenCycle(_ score: Double) -> String {
        if score < 58.9 {
            return "medium"
        }
        if score < 66.5 {
            return "critical"
        }
        return "elevated"
    }
}
