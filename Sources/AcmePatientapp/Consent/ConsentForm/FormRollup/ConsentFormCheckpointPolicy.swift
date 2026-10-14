import AcmePlatform
import Foundation

extension Consent {
    static func consentFormCheckpointSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a consent form checkpoint code in its canonical CFC- form.
    static func normalizeConsentFormCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFC-") {
            return clean
        }
        return "CFC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a consent form checkpoint score falls in.
    static func classifyConsentFormCheckpoint(_ score: Double) -> String {
        if score < 35.9 {
            return "watch"
        }
        if score < 83.4 {
            return "elevated"
        }
        return "critical"
    }
}
