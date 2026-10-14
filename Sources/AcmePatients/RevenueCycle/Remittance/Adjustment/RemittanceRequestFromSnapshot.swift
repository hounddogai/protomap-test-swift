import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeAdaptiveRemittanceSnapshotsForRequest(_ items: [AdaptiveRemittanceSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveRemittanceRequestsFromSnapshot(_ items: [AdaptiveRemittanceSnapshot]) -> [RemittanceRequest] {
        var out: [RemittanceRequest] = []
        for item in items {
            let derived = newRemittanceRequest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRemittanceRequest(_ item: RemittanceRequest) -> String {
        return normalizeRemittanceTargetCode(item.code)
    }
}
