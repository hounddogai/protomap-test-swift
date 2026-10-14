import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingOrderSetGroupsForManifest(_ items: [PendingOrderSetGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientCareProtocolManifestsFromGroup(_ items: [PendingOrderSetGroup]) -> [LenientCareProtocolManifest] {
        var out: [LenientCareProtocolManifest] = []
        for item in items {
            let derived = newLenientCareProtocolManifest(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveLenientCareProtocolManifest(_ item: LenientCareProtocolManifest) -> String {
        return normalizeBatchedOrderSetExceptionCode(item.code)
    }
}
