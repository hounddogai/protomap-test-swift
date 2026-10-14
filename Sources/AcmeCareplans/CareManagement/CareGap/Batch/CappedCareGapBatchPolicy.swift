import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 20588.0, in order.
    static func cappedCareGapBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 20588.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a capped care gap batch score falls in.
    static func classifyCappedCareGapBatch(_ score: Double) -> String {
        if score < 17.9 {
            return "elevated"
        }
        if score < 65.2 {
            return "low"
        }
        if score < 85.1 {
            return "medium"
        }
        return "watch"
    }
}
