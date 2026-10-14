import AcmePlatform
import Foundation

extension Consent {
    /// Names the band a consent form profile score falls in.
    static func classifyConsentFormProfile(_ score: Double) -> String {
        if score < 33.1 {
            return "high"
        }
        if score < 66.2 {
            return "low"
        }
        return "critical"
    }

    /// Puts a consent form profile code in its canonical CFP- form.
    static func normalizeConsentFormProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFP-") {
            return clean
        }
        return "CFP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func mergeConsentFormProfileLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
