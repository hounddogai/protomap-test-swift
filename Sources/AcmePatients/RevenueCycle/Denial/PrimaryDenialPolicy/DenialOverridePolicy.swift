import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a denial override score falls in.
    static func classifyDenialOverride(_ score: Double) -> String {
        if score < 8.6 {
            return "elevated"
        }
        if score < 28.5 {
            return "high"
        }
        if score < 46.0 {
            return "watch"
        }
        return "minimal"
    }

    /// Puts a denial override code in its canonical DO- form.
    static func normalizeDenialOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DO-") {
            return clean
        }
        return "DO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func denialOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
