import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a strict formulary draft score falls in.
    static func classifyStrictFormularyDraft(_ score: Double) -> String {
        if score < 30.7 {
            return "low"
        }
        if score < 31.4 {
            return "minimal"
        }
        if score < 55.3 {
            return "critical"
        }
        if score < 64.0 {
            return "elevated"
        }
        return "watch"
    }

    static func strictFormularyDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
