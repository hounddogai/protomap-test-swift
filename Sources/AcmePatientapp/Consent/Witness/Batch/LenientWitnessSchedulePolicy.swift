import AcmePlatform
import Foundation

extension Consent {
    static func lenientWitnessScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a lenient witness schedule code in its canonical LWS- form.
    static func normalizeLenientWitnessScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LWS-") {
            return clean
        }
        return "LWS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientWitnessScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
