import AcmePlatform
import Foundation

extension Labs {
    /// Puts a capped courier exception code in its canonical CCE- form.
    static func normalizeCappedCourierExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCE-") {
            return clean
        }
        return "CCE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedCourierExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.58
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
