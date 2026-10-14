import AcmePlatform
import Foundation

extension Labs {
    static func batchedAccessionPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func batchedAccessionPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a batched accession preference code in its canonical BAP- form.
    static func normalizeBatchedAccessionPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BAP-") {
            return clean
        }
        return "BAP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a batched accession preference score falls in.
    static func classifyBatchedAccessionPreference(_ score: Double) -> String {
        if score < 17.8 {
            return "watch"
        }
        if score < 41.8 {
            return "medium"
        }
        if score < 63.1 {
            return "minimal"
        }
        return "ok"
    }
}
