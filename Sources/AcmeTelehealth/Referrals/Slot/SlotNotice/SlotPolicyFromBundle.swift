import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultNetworkBundlesForPolicy(_ items: [DefaultNetworkBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveSlotPoliciesFromBundle(_ items: [DefaultNetworkBundle]) -> [SlotPolicy] {
        var out: [SlotPolicy] = []
        for item in items {
            let derived = newSlotPolicy(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignSlotPolicy(_ item: SlotPolicy) -> String {
        return classifyDefaultNetworkBundle(item.netExposure())
    }
}
