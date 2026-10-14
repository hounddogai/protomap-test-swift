import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a lenient assessment score score falls in.
    static func classifyLenientAssessmentScore(_ score: Double) -> String {
        if score < 5.9 {
            return "critical"
        }
        if score < 43.1 {
            return "watch"
        }
        if score < 74.9 {
            return "elevated"
        }
        return "medium"
    }

    static func lenientAssessmentScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 47473.0, in order.
    static func lenientAssessmentScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47473.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a lenient assessment score code in its canonical LAS- form.
    static func normalizeLenientAssessmentScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAS-") {
            return clean
        }
        return "LAS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
