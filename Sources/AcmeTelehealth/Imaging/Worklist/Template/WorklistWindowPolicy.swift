import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a worklist window score falls in.
    static func classifyWorklistWindow(_ score: Double) -> String {
        if score < 19.1 {
            return "low"
        }
        if score < 67.6 {
            return "high"
        }
        return "minimal"
    }

    /// Puts a worklist window code in its canonical WW- form.
    static func normalizeWorklistWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WW-") {
            return clean
        }
        return "WW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func worklistWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
