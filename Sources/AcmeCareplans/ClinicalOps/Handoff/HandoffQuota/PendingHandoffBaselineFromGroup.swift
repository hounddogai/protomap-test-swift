import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingOrderSetGroupsForBaseline(_ items: [PendingOrderSetGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingHandoffBaselinesFromGroup(_ items: [PendingOrderSetGroup]) -> [PendingHandoffBaseline] {
        var out: [PendingHandoffBaseline] = []
        for item in items {
            let derived = newPendingHandoffBaseline(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balancePendingHandoffBaseline(_ item: PendingHandoffBaseline) -> String {
        return classifyPendingOrderSetGroup(item.effectiveValue())
    }
}
