import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a strict shift digest code in its canonical SSD- form.
    static func normalizeStrictShiftDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSD-") {
            return clean
        }
        return "SSD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a strict shift digest score falls in.
    static func classifyStrictShiftDigest(_ score: Double) -> String {
        if score < 27.8 {
            return "medium"
        }
        if score < 39.2 {
            return "low"
        }
        if score < 74.1 {
            return "minimal"
        }
        if score < 95.1 {
            return "watch"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 79327.0, in order.
    static func strictShiftDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79327.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictShiftDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
