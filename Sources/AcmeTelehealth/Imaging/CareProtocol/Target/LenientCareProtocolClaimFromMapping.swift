import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeScheduledPriorityMappingsForClaim(_ items: [ScheduledPriorityMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLenientCareProtocolClaimsFromMapping(_ items: [ScheduledPriorityMapping]) -> [LenientCareProtocolClaim] {
        var out: [LenientCareProtocolClaim] = []
        for item in items {
            let derived = newLenientCareProtocolClaim(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchLenientCareProtocolClaim(_ item: LenientCareProtocolClaim) -> String {
        return normalizePriorityTierCode(item.code)
    }
}
