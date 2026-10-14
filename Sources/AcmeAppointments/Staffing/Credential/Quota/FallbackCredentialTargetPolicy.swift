import AcmePlatform
import Foundation

extension Staffing {
    static func fallbackCredentialTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a fallback credential target code in its canonical FCT- form.
    static func normalizeFallbackCredentialTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FCT-") {
            return clean
        }
        return "FCT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
