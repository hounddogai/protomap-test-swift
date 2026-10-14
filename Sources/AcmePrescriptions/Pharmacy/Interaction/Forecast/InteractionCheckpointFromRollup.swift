import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeManualFormularyRollupsForCheckpoint(_ items: [ManualFormularyRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveInteractionCheckpointsFromRollup(_ items: [ManualFormularyRollup]) -> [InteractionCheckpoint] {
        var out: [InteractionCheckpoint] = []
        for item in items {
            let derived = newInteractionCheckpoint(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeInteractionCheckpoint(_ item: InteractionCheckpoint) -> Double {
        return batchedFormularyPolicyWeight(6, active: true)
    }
}
