import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpVariancesForLedger(_ items: [FollowUpVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveDefaultSlotLedgersFromVariance(_ items: [FollowUpVariance]) -> [DefaultSlotLedger] {
        var out: [DefaultSlotLedger] = []
        for item in items {
            let derived = newDefaultSlotLedger(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDefaultSlotLedger(_ item: DefaultSlotLedger) -> String {
        return adaptiveFollowUpPolicyBucket(item.adjustedExposure())
    }
}
