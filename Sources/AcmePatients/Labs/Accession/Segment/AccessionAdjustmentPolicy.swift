import AcmePlatform
import Foundation

extension Labs {
    static func accessionAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a accession adjustment score falls in.
    static func classifyAccessionAdjustment(_ score: Double) -> String {
        if score < 12.1 {
            return "ok"
        }
        if score < 50.4 {
            return "high"
        }
        return "minimal"
    }

    /// Puts a accession adjustment code in its canonical AA- form.
    static func normalizeAccessionAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AA-") {
            return clean
        }
        return "AA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
