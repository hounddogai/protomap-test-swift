import AcmePlatform
import Foundation

extension BedManagement {
    static func manualIsolationCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 50465.0, in order.
    static func manualIsolationCycleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50465.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a manual isolation cycle score falls in.
    static func classifyManualIsolationCycle(_ score: Double) -> String {
        if score < 6.2 {
            return "medium"
        }
        if score < 19.8 {
            return "low"
        }
        if score < 24.9 {
            return "ok"
        }
        if score < 92.0 {
            return "elevated"
        }
        return "critical"
    }
}
