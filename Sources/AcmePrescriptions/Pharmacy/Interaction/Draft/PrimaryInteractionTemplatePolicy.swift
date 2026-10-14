import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 36627.0, in order.
    static func primaryInteractionTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36627.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a primary interaction template score falls in.
    static func classifyPrimaryInteractionTemplate(_ score: Double) -> String {
        if score < 24.1 {
            return "low"
        }
        if score < 36.4 {
            return "high"
        }
        if score < 89.2 {
            return "medium"
        }
        return "ok"
    }

    static func primaryInteractionTemplateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
