import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedAuthorizationEntriesForNotice(_ items: [BatchedAuthorizationEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func derivePendingStatementNoticesFromEntry(_ items: [BatchedAuthorizationEntry]) -> [PendingStatementNotice] {
        var out: [PendingStatementNotice] = []
        for item in items {
            let derived = newPendingStatementNotice(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizePendingStatementNotice(_ item: PendingStatementNotice) -> String {
        return authorizationScoreBucket(item.netTotal())
    }

    static func summarizeCappedChargeEntriesForNotice(_ items: [CappedChargeEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func derivePendingStatementNoticesFromEntryExtra(_ items: [CappedChargeEntry]) -> [PendingStatementNotice] {
        var out: [PendingStatementNotice] = []
        for item in items {
            let derived = newPendingStatementNotice(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePendingStatementNotice(_ item: PendingStatementNotice) -> String {
        return classifyWeightedChargeTier(item.netTotal())
    }
}
