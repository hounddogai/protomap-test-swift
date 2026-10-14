import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a primary order set variance code in its canonical POSV- form.
    static func normalizePrimaryOrderSetVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("POSV-") {
            return clean
        }
        return "POSV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryOrderSetVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.67
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func primaryOrderSetVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
