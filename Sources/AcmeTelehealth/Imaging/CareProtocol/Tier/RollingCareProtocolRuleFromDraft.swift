import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingReadDraftsForRule(_ items: [PendingReadDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveRollingCareProtocolRulesFromDraft(_ items: [PendingReadDraft]) -> [RollingCareProtocolRule] {
        var out: [RollingCareProtocolRule] = []
        for item in items {
            let derived = newRollingCareProtocolRule(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRollingCareProtocolRule(_ item: RollingCareProtocolRule) -> String {
        return pendingReadDraftBucket(item.adjustedTotal())
    }
}
