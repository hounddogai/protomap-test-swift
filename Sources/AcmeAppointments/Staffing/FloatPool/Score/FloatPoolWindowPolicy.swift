import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a float pool window code in its canonical FPW- form.
    static func normalizeFloatPoolWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPW-") {
            return clean
        }
        return "FPW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a float pool window score falls in.
    static func classifyFloatPoolWindow(_ score: Double) -> String {
        if score < 47.5 {
            return "watch"
        }
        if score < 47.9 {
            return "elevated"
        }
        if score < 82.1 {
            return "critical"
        }
        if score < 90.0 {
            return "medium"
        }
        return "low"
    }
}
