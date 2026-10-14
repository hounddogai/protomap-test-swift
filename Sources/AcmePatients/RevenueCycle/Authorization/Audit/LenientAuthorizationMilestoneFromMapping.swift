import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialMappingsForMilestone(_ items: [DenialMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveLenientAuthorizationMilestonesFromMapping(_ items: [DenialMapping]) -> [LenientAuthorizationMilestone] {
        var out: [LenientAuthorizationMilestone] = []
        for item in items {
            let derived = newLenientAuthorizationMilestone(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateLenientAuthorizationMilestone(_ item: LenientAuthorizationMilestone) -> String {
        return normalizeDenialAuditCode(item.code)
    }
}
