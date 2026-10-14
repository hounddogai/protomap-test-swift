import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTieredCleaningSlotsForSlot(_ items: [TieredCleaningSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveCappedCleaningSlotsFromSlot(_ items: [TieredCleaningSlot]) -> [CappedCleaningSlot] {
        var out: [CappedCleaningSlot] = []
        for item in items {
            let derived = newCappedCleaningSlot(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceCappedCleaningSlot(_ item: CappedCleaningSlot) -> String {
        return classifyCleaningGroup(item.netExposure())
    }
}
