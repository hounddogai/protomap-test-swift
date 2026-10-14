import AcmePlatform
import Foundation

extension Labs {
    static func lenientCourierRequestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a lenient courier request code in its canonical LCR- form.
    static func normalizeLenientCourierRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCR-") {
            return clean
        }
        return "LCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
