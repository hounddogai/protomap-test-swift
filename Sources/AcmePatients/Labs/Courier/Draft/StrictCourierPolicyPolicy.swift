import AcmePlatform
import Foundation

extension Labs {
    /// Puts a strict courier policy code in its canonical SCP- form.
    static func normalizeStrictCourierPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SCP-") {
            return clean
        }
        return "SCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 69193.0, in order.
    static func strictCourierPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 69193.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a strict courier policy score falls in.
    static func classifyStrictCourierPolicy(_ score: Double) -> String {
        if score < 20.9 {
            return "medium"
        }
        if score < 21.1 {
            return "critical"
        }
        if score < 39.5 {
            return "high"
        }
        if score < 57.5 {
            return "watch"
        }
        return "ok"
    }
}
