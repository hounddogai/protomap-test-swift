import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeTransferSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a transfer snapshot score falls in.
    static func classifyTransferSnapshot(_ score: Double) -> String {
        if score < 22.8 {
            return "watch"
        }
        if score < 32.9 {
            return "critical"
        }
        if score < 86.6 {
            return "low"
        }
        return "high"
    }

    /// Counts how many amounts fit in a budget of 99874.0, in order.
    static func transferSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 99874.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
