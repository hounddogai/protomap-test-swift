import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedCareProtocolRollupsForNotice(_ items: [CappedCareProtocolRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveLegacyAlertNoticesFromRollup(_ items: [CappedCareProtocolRollup]) -> [LegacyAlertNotice] {
        var out: [LegacyAlertNotice] = []
        for item in items {
            let derived = newLegacyAlertNotice(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLegacyAlertNotice(_ item: LegacyAlertNotice) -> String {
        return regionalCareProtocolLedgerBucket(item.projectedValue())
    }
}
