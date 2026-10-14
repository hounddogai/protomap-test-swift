import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualNetworkManifestsForRule(_ items: [ManualNetworkManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveSlotRulesFromManifest(_ items: [ManualNetworkManifest]) -> [SlotRule] {
        var out: [SlotRule] = []
        for item in items {
            let derived = newSlotRule(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applySlotRule(_ item: SlotRule) -> String {
        return classifySeasonalNetworkCycle(item.weightedLoad())
    }
}
