import AcmePlatform
import Foundation

extension Consent {
    static func summarizeCappedLanguagePlansForSlot(_ items: [CappedLanguagePlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveWitnessSlotsFromPlan(_ items: [CappedLanguagePlan]) -> [WitnessSlot] {
        var out: [WitnessSlot] = []
        for item in items {
            let derived = newWitnessSlot(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceWitnessSlot(_ item: WitnessSlot) -> String {
        return languageTierBucket(item.effectiveLoad())
    }
}
