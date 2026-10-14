import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a study policy code in its canonical SP- form.
    static func normalizeStudyPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SP-") {
            return clean
        }
        return "SP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 57218.0, in order.
    static func studyPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57218.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func studyPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.87
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a study policy score falls in.
    static func classifyStudyPolicy(_ score: Double) -> String {
        if score < 40.6 {
            return "ok"
        }
        if score < 57.8 {
            return "minimal"
        }
        if score < 83.7 {
            return "low"
        }
        return "elevated"
    }
}
