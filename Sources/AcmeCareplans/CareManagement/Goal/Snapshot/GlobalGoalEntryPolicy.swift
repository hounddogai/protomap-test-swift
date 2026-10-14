import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a global goal entry score falls in.
    static func classifyGlobalGoalEntry(_ score: Double) -> String {
        if score < 19.2 {
            return "ok"
        }
        if score < 21.3 {
            return "elevated"
        }
        return "minimal"
    }

    /// Puts a global goal entry code in its canonical GGE- form.
    static func normalizeGlobalGoalEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GGE-") {
            return clean
        }
        return "GGE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 44976.0, in order.
    static func globalGoalEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44976.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
