import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolTiersForRequest(_ items: [CareProtocolTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveCareProtocolRequestsFromTier(_ items: [CareProtocolTier]) -> [CareProtocolRequest] {
        var out: [CareProtocolRequest] = []
        for item in items {
            let derived = newCareProtocolRequest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeCareProtocolRequest(_ item: CareProtocolRequest) -> String {
        return strictCareProtocolTargetBucket(item.weightedValue())
    }
}
