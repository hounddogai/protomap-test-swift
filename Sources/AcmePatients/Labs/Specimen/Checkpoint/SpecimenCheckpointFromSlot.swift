import AcmePlatform
import Foundation

extension Labs {
    static func summarizeGlobalResultSlotsForCheckpoint(_ items: [GlobalResultSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveSpecimenCheckpointsFromSlot(_ items: [GlobalResultSlot]) -> [SpecimenCheckpoint] {
        var out: [SpecimenCheckpoint] = []
        for item in items {
            let derived = newSpecimenCheckpoint(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveSpecimenCheckpoint(_ item: SpecimenCheckpoint) -> Double {
        return globalResultSlotWeight(1, active: true)
    }
}
