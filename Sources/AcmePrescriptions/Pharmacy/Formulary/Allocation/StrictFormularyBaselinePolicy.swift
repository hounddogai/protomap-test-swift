import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a strict formulary baseline code in its canonical SFB- form.
    static func normalizeStrictFormularyBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SFB-") {
            return clean
        }
        return "SFB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictFormularyBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func strictFormularyBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a strict formulary baseline score falls in.
    static func classifyStrictFormularyBaseline(_ score: Double) -> String {
        if score < 12.9 {
            return "ok"
        }
        if score < 36.0 {
            return "watch"
        }
        return "elevated"
    }
}
