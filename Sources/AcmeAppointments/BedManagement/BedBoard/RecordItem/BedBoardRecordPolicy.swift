import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 21297.0, in order.
    static func bedBoardRecordBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 21297.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a bed board record score falls in.
    static func classifyBedBoardRecord(_ score: Double) -> String {
        if score < 73.8 {
            return "critical"
        }
        if score < 87.7 {
            return "medium"
        }
        if score < 93.2 {
            return "ok"
        }
        return "elevated"
    }

    static func bedBoardRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
