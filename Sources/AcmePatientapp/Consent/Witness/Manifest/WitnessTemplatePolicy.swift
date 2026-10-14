import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a witness template score falls in.
    static func classifyWitnessTemplate(_ score: Double) -> String {
        if score < 45.7 {
            return "high"
        }
        if score < 77.4 {
            return "low"
        }
        return "elevated"
    }

    static func witnessTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a witness template code in its canonical WT- form.
    static func normalizeWitnessTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WT-") {
            return clean
        }
        return "WT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 8135.0, in order.
    static func witnessTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 8135.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
