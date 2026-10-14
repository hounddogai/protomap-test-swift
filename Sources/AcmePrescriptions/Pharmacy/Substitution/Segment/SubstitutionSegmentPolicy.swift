import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a substitution segment code in its canonical SS- form.
    static func normalizeSubstitutionSegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SS-") {
            return clean
        }
        return "SS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func substitutionSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 2752.0, in order.
    static func substitutionSegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2752.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a substitution segment score falls in.
    static func classifySubstitutionSegment(_ score: Double) -> String {
        if score < 18.2 {
            return "ok"
        }
        if score < 25.5 {
            return "high"
        }
        if score < 60.7 {
            return "minimal"
        }
        return "low"
    }
}
