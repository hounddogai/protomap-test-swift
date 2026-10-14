import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCareProtocolNoticesForClaim(_ items: [CareProtocolNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveAdaptivePriorityClaimsFromNotice(_ items: [CareProtocolNotice]) -> [AdaptivePriorityClaim] {
        var out: [AdaptivePriorityClaim] = []
        for item in items {
            let derived = newAdaptivePriorityClaim(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAdaptivePriorityClaim(_ item: AdaptivePriorityClaim) -> String {
        return classifyCareProtocolNotice(item.netValue())
    }
}
