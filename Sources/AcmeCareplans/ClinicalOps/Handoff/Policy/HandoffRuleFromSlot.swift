import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryRoundingSlotsForRule(_ items: [PrimaryRoundingSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveHandoffRulesFromSlot(_ items: [PrimaryRoundingSlot]) -> [HandoffRule] {
        var out: [HandoffRule] = []
        for item in items {
            let derived = newHandoffRule(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectHandoffRule(_ item: HandoffRule) -> String {
        return normalizePrimaryRoundingSlotCode(item.code)
    }
}
