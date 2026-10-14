import AcmePlatform
import Foundation

extension Staffing {
    static func manualOvertimeVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a manual overtime variance code in its canonical MOV- form.
    static func normalizeManualOvertimeVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MOV-") {
            return clean
        }
        return "MOV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func manualOvertimeVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
