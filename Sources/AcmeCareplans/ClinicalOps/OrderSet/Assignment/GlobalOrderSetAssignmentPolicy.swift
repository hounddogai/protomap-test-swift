import AcmePlatform
import Foundation

extension ClinicalOps {
    static func globalOrderSetAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a global order set assignment code in its canonical GOSA- form.
    static func normalizeGlobalOrderSetAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GOSA-") {
            return clean
        }
        return "GOSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a global order set assignment score falls in.
    static func classifyGlobalOrderSetAssignment(_ score: Double) -> String {
        if score < 43.2 {
            return "low"
        }
        if score < 83.0 {
            return "medium"
        }
        return "watch"
    }
}
