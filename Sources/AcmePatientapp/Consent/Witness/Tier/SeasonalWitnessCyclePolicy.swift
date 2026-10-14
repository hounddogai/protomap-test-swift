import AcmePlatform
import Foundation

extension Consent {
    /// Puts a seasonal witness cycle code in its canonical SWC- form.
    static func normalizeSeasonalWitnessCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWC-") {
            return clean
        }
        return "SWC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 15936.0, in order.
    static func seasonalWitnessCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15936.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func seasonalWitnessCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
