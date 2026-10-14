import AcmePlatform
import Foundation

extension Labs {
    static func strictSpecimenPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func strictSpecimenPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a strict specimen plan code in its canonical SSP- form.
    static func normalizeStrictSpecimenPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSP-") {
            return clean
        }
        return "SSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
