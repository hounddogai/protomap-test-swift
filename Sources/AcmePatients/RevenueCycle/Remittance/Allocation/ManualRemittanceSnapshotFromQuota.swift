import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialQuotasForSnapshot(_ items: [DenialQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveManualRemittanceSnapshotsFromQuota(_ items: [DenialQuota]) -> [ManualRemittanceSnapshot] {
        var out: [ManualRemittanceSnapshot] = []
        for item in items {
            let derived = newManualRemittanceSnapshot(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeManualRemittanceSnapshot(_ item: ManualRemittanceSnapshot) -> String {
        return normalizeDenialQuotaCode(item.code)
    }
}
