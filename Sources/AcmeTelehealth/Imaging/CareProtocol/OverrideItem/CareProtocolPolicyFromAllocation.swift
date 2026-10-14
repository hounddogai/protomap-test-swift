import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeDefaultCareProtocolAllocationsForPolicy(_ items: [DefaultCareProtocolAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveCareProtocolPoliciesFromAllocation(_ items: [DefaultCareProtocolAllocation]) -> [CareProtocolPolicy] {
        var out: [CareProtocolPolicy] = []
        for item in items {
            let derived = newCareProtocolPolicy(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeCareProtocolPolicy(_ item: CareProtocolPolicy) -> String {
        return careProtocolDigestBucket(item.adjustedLoad())
    }
}
