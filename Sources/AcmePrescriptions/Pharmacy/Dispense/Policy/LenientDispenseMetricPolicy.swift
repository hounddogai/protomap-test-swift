import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a lenient dispense metric code in its canonical LDM- form.
    static func normalizeLenientDispenseMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDM-") {
            return clean
        }
        return "LDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientDispenseMetricWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.45
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func lenientDispenseMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a lenient dispense metric score falls in.
    static func classifyLenientDispenseMetric(_ score: Double) -> String {
        if score < 5.8 {
            return "critical"
        }
        if score < 49.0 {
            return "watch"
        }
        return "elevated"
    }
}
