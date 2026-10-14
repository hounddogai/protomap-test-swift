import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryDenialMetricsForDraft(_ items: [PrimaryDenialMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func derivePendingChargeDraftsFromMetric(_ items: [PrimaryDenialMetric]) -> [PendingChargeDraft] {
        var out: [PendingChargeDraft] = []
        for item in items {
            let derived = newPendingChargeDraft(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectPendingChargeDraft(_ item: PendingChargeDraft) -> String {
        return classifyPendingDenialOverride(item.projectedLoad())
    }
}
