import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a lenient isolation baseline code in its canonical LIB- form.
    static func normalizeLenientIsolationBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LIB-") {
            return clean
        }
        return "LIB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient isolation baseline score falls in.
    static func classifyLenientIsolationBaseline(_ score: Double) -> String {
        if score < 2.4 {
            return "minimal"
        }
        if score < 44.1 {
            return "watch"
        }
        if score < 44.3 {
            return "ok"
        }
        if score < 65.4 {
            return "low"
        }
        return "critical"
    }

    static func lenientIsolationBaselineWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 9311.0, in order.
    static func lenientIsolationBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 9311.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
