import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 22271.0, in order.
    static func fallbackCourierDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 22271.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a fallback courier draft score falls in.
    static func classifyFallbackCourierDraft(_ score: Double) -> String {
        if score < 49.9 {
            return "ok"
        }
        if score < 88.7 {
            return "low"
        }
        return "critical"
    }

    static func fallbackCourierDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }
}
