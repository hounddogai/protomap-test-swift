import AcmePlatform
import Foundation

extension Pharmacy {
    static func dispenseForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a dispense forecast code in its canonical DF- form.
    static func normalizeDispenseForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DF-") {
            return clean
        }
        return "DF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func dispenseForecastWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
