import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a shift manifest code in its canonical SM- form.
    static func normalizeShiftManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SM-") {
            return clean
        }
        return "SM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func shiftManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
