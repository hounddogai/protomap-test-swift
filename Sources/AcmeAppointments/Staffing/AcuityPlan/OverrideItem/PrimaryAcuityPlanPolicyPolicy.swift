import AcmePlatform
import Foundation

extension Staffing {
    /// Counts how many amounts fit in a budget of 47792.0, in order.
    static func primaryAcuityPlanPolicyBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 47792.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary acuity plan policy score falls in.
    static func classifyPrimaryAcuityPlanPolicy(_ score: Double) -> String {
        if score < 36.8 {
            return "watch"
        }
        if score < 41.7 {
            return "medium"
        }
        if score < 64.3 {
            return "elevated"
        }
        if score < 88.5 {
            return "minimal"
        }
        return "critical"
    }

    static func primaryAcuityPlanPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.77
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a primary acuity plan policy code in its canonical PAPP- form.
    static func normalizePrimaryAcuityPlanPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAPP-") {
            return clean
        }
        return "PAPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
