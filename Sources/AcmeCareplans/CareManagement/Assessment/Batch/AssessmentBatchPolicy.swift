import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 14567.0, in order.
    static func assessmentBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14567.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func assessmentBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a assessment batch score falls in.
    static func classifyAssessmentBatch(_ score: Double) -> String {
        if score < 16.2 {
            return "high"
        }
        if score < 47.2 {
            return "minimal"
        }
        if score < 86.2 {
            return "watch"
        }
        return "ok"
    }
}
