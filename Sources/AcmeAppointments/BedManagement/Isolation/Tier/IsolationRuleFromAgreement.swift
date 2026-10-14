import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferAgreementsForRule(_ items: [TransferAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveIsolationRulesFromAgreement(_ items: [TransferAgreement]) -> [IsolationRule] {
        var out: [IsolationRule] = []
        for item in items {
            let derived = newIsolationRule(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateIsolationRule(_ item: IsolationRule) -> String {
        return transferBaselineBucket(item.effectiveValue())
    }
}
