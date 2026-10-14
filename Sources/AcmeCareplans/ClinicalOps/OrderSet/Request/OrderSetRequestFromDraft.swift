import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCappedCareProtocolDraftsForRequest(_ items: [CappedCareProtocolDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveOrderSetRequestsFromDraft(_ items: [CappedCareProtocolDraft]) -> [OrderSetRequest] {
        var out: [OrderSetRequest] = []
        for item in items {
            let derived = newOrderSetRequest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeOrderSetRequest(_ item: OrderSetRequest) -> Double {
        return cappedCareProtocolDraftWeight(6, active: true)
    }
}
