import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a manual denial ledger score falls in.
    static func classifyManualDenialLedger(_ score: Double) -> String {
        if score < 2.1 {
            return "ok"
        }
        if score < 12.8 {
            return "minimal"
        }
        if score < 44.1 {
            return "medium"
        }
        if score < 87.0 {
            return "critical"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 11247.0, in order.
    static func manualDenialLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 11247.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
