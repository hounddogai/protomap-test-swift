import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRollingFormularySnapshotsForTarget(_ items: [RollingFormularySnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func derivePrimaryInventoryTargetsFromSnapshot(_ items: [RollingFormularySnapshot]) -> [PrimaryInventoryTarget] {
        var out: [PrimaryInventoryTarget] = []
        for item in items {
            let derived = newPrimaryInventoryTarget(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePrimaryInventoryTarget(_ item: PrimaryInventoryTarget) -> String {
        return adaptiveFormularyDigestBucket(item.measuredValue())
    }
}
