import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyRulesForRequest(_ items: [FormularyRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCappedInventoryRequestsFromRule(_ items: [FormularyRule]) -> [CappedInventoryRequest] {
        var out: [CappedInventoryRequest] = []
        for item in items {
            let derived = newCappedInventoryRequest(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyCappedInventoryRequestExtra(_ item: CappedInventoryRequest) -> String {
        return normalizeFormularyDraftCode(item.code)
    }
}
