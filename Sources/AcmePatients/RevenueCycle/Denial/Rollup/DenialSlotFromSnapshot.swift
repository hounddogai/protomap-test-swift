import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeManualRemittanceSnapshotsForSlot(_ items: [ManualRemittanceSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveDenialSlotsFromSnapshot(_ items: [ManualRemittanceSnapshot]) -> [DenialSlot] {
        var out: [DenialSlot] = []
        for item in items {
            let derived = newDenialSlot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitDenialSlot(_ item: DenialSlot) -> String {
        return remittanceMappingBucket(item.netExposure())
    }
}
