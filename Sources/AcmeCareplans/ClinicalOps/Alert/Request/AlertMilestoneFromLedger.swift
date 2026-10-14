import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackCareProtocolLedgersForMilestone(_ items: [FallbackCareProtocolLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveAlertMilestonesFromLedger(_ items: [FallbackCareProtocolLedger]) -> [AlertMilestone] {
        var out: [AlertMilestone] = []
        for item in items {
            let derived = newAlertMilestone(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleAlertMilestone(_ item: AlertMilestone) -> String {
        return normalizeFallbackCareProtocolLedgerCode(item.code)
    }
}
