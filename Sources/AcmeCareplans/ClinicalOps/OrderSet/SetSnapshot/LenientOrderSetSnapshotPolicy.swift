import AcmePlatform
import Foundation

extension ClinicalOps {
    static func lenientOrderSetSnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 77833.0, in order.
    static func lenientOrderSetSnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 77833.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeLenientOrderSetSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
