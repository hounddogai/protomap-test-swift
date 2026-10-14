import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a rolling formulary segment score falls in.
    static func classifyRollingFormularySegment(_ score: Double) -> String {
        if score < 1.1 {
            return "critical"
        }
        if score < 76.8 {
            return "ok"
        }
        if score < 79.8 {
            return "low"
        }
        if score < 80.4 {
            return "watch"
        }
        return "medium"
    }

    /// Puts a rolling formulary segment code in its canonical RFS- form.
    static func normalizeRollingFormularySegmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFS-") {
            return clean
        }
        return "RFS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingFormularySegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.1
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 82758.0, in order.
    static func rollingFormularySegmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82758.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
