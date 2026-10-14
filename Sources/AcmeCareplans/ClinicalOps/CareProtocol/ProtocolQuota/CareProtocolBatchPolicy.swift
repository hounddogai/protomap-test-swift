import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol batch score falls in.
    static func classifyCareProtocolBatch(_ score: Double) -> String {
        if score < 2.4 {
            return "medium"
        }
        if score < 29.6 {
            return "elevated"
        }
        if score < 58.7 {
            return "watch"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 99189.0, in order.
    static func careProtocolBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99189.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
