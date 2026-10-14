import AcmePlatform
import Foundation

extension Staffing {
    static func credentialWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a credential window score falls in.
    static func classifyCredentialWindow(_ score: Double) -> String {
        if score < 16.8 {
            return "critical"
        }
        if score < 34.9 {
            return "high"
        }
        if score < 52.0 {
            return "elevated"
        }
        return "minimal"
    }

    /// Puts a credential window code in its canonical CW- form.
    static func normalizeCredentialWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CW-") {
            return clean
        }
        return "CW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
