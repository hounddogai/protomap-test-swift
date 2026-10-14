import AcmePlatform
import Foundation

extension Consent {
    static func lenientRevocationGroupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a lenient revocation group score falls in.
    static func classifyLenientRevocationGroup(_ score: Double) -> String {
        if score < 13.9 {
            return "critical"
        }
        if score < 41.8 {
            return "elevated"
        }
        if score < 68.9 {
            return "high"
        }
        return "ok"
    }

    /// Puts a lenient revocation group code in its canonical LRG- form.
    static func normalizeLenientRevocationGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRG-") {
            return clean
        }
        return "LRG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientRevocationGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }
}
