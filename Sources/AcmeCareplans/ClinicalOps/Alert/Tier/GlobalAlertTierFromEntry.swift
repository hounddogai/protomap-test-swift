import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertEntriesForTier(_ items: [AlertEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveGlobalAlertTiersFromEntry(_ items: [AlertEntry]) -> [GlobalAlertTier] {
        var out: [GlobalAlertTier] = []
        for item in items {
            let derived = newGlobalAlertTier(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyGlobalAlertTier(_ item: GlobalAlertTier) -> Double {
        return alertCycleWeight(1, active: true)
    }
}
