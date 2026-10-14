import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a lenient network score code in its canonical LNS- form.
    static func normalizeLenientNetworkScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LNS-") {
            return clean
        }
        return "LNS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient network score score falls in.
    static func classifyLenientNetworkScore(_ score: Double) -> String {
        if score < 9.8 {
            return "low"
        }
        if score < 51.3 {
            return "minimal"
        }
        if score < 74.4 {
            return "ok"
        }
        return "watch"
    }
}
