import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotCheckpointsForRule(_ items: [SlotCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveEligibilityRulesFromCheckpoint(_ items: [SlotCheckpoint]) -> [EligibilityRule] {
        var out: [EligibilityRule] = []
        for item in items {
            let derived = newEligibilityRule(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreEligibilityRule(_ item: EligibilityRule) -> String {
        return normalizeSlotBundleCode(item.code)
    }
}
