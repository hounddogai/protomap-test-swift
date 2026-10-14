import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLegacyIsolationAllocationsForRequest(_ items: [LegacyIsolationAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveFallbackTransferRequestsFromAllocation(_ items: [LegacyIsolationAllocation]) -> [FallbackTransferRequest] {
        var out: [FallbackTransferRequest] = []
        for item in items {
            let derived = newFallbackTransferRequest(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignFallbackTransferRequest(_ item: FallbackTransferRequest) -> Double {
        return strictIsolationDigestWeight(9, active: true)
    }
}
