import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLenientNetworkSnapshotsForRequest(_ items: [LenientNetworkSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveClosureRequestsFromSnapshot(_ items: [LenientNetworkSnapshot]) -> [ClosureRequest] {
        var out: [ClosureRequest] = []
        for item in items {
            let derived = newClosureRequest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignClosureRequest(_ item: ClosureRequest) -> String {
        return batchedNetworkAgreementBucket(item.effectiveLoad())
    }
}
