import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a weighted panel ledger score falls in.
    static func classifyWeightedPanelLedger(_ score: Double) -> String {
        if score < 8.1 {
            return "medium"
        }
        if score < 32.0 {
            return "elevated"
        }
        if score < 59.2 {
            return "ok"
        }
        return "low"
    }

    static func weightedPanelLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
