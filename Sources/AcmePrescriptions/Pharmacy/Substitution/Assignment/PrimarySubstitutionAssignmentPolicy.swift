import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 18280.0, in order.
    static func primarySubstitutionAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 18280.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary substitution assignment score falls in.
    static func classifyPrimarySubstitutionAssignment(_ score: Double) -> String {
        if score < 14.0 {
            return "ok"
        }
        if score < 35.3 {
            return "low"
        }
        if score < 93.4 {
            return "medium"
        }
        return "critical"
    }

    /// Puts a primary substitution assignment code in its canonical PSA- form.
    static func normalizePrimarySubstitutionAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSA-") {
            return clean
        }
        return "PSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primarySubstitutionAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
