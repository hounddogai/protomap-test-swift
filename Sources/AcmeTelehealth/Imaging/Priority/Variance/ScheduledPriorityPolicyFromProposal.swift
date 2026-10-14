import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePendingReadProposalsForPolicy(_ items: [PendingReadProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledPriorityPoliciesFromProposal(_ items: [PendingReadProposal]) -> [ScheduledPriorityPolicy] {
        var out: [ScheduledPriorityPolicy] = []
        for item in items {
            let derived = newScheduledPriorityPolicy(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankScheduledPriorityPolicy(_ item: ScheduledPriorityPolicy) -> String {
        return lenientReadProposalBucket(item.effectiveVolume())
    }
}
