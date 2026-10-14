import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryRemittanceSummariesForTier(_ items: [PrimaryRemittanceSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveManualDenialTiersFromSummary(_ items: [PrimaryRemittanceSummary]) -> [ManualDenialTier] {
        var out: [ManualDenialTier] = []
        for item in items {
            let derived = newManualDenialTier(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleManualDenialTier(_ item: ManualDenialTier) -> String {
        return normalizeRemittanceNoticeCode(item.code)
    }
}
