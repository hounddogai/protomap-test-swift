import AcmePlatform
import Foundation

extension Consent {
    /// Puts a rolling witness assignment code in its canonical RWA- form.
    static func normalizeRollingWitnessAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RWA-") {
            return clean
        }
        return "RWA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingWitnessAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func rollingWitnessAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.61
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
