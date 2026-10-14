import AcmePlatform
import Foundation

extension Consent {
    static func summarizeStrictDisclosureSegmentsForGroup(_ items: [StrictDisclosureSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveScheduledProxyGroupsFromSegment(_ items: [StrictDisclosureSegment]) -> [ScheduledProxyGroup] {
        var out: [ScheduledProxyGroup] = []
        for item in items {
            let derived = newScheduledProxyGroup(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitScheduledProxyGroup(_ item: ScheduledProxyGroup) -> String {
        return disclosureRequestBucket(item.projectedLoad())
    }
}
