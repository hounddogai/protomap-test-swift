import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a strict interaction audit code in its canonical SIA- form.
    static func normalizeStrictInteractionAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIA-") {
            return clean
        }
        return "SIA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictInteractionAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.79
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 91105.0, in order.
    static func strictInteractionAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91105.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a strict interaction audit score falls in.
    static func classifyStrictInteractionAudit(_ score: Double) -> String {
        if score < 8.4 {
            return "medium"
        }
        if score < 10.7 {
            return "watch"
        }
        if score < 33.3 {
            return "minimal"
        }
        if score < 39.8 {
            return "ok"
        }
        return "critical"
    }
}
