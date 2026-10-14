import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a default charge ledger score falls in.
    static func classifyDefaultChargeLedger(_ score: Double) -> String {
        if score < 30.0 {
            return "ok"
        }
        if score < 54.9 {
            return "high"
        }
        return "low"
    }

    static func defaultChargeLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.72
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
