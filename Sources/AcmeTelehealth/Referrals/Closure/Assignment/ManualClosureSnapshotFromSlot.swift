import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedEligibilitySlotsForSnapshot(_ items: [WeightedEligibilitySlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualClosureSnapshotsFromSlot(_ items: [WeightedEligibilitySlot]) -> [ManualClosureSnapshot] {
        var out: [ManualClosureSnapshot] = []
        for item in items {
            let derived = newManualClosureSnapshot(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeManualClosureSnapshot(_ item: ManualClosureSnapshot) -> Double {
        return fallbackEligibilityScoreWeight(4, active: true)
    }
}
