import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialMappingsForMilestoneMilestone(_ items: [DenialMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveClaimMilestonesFromMapping(_ items: [DenialMapping]) -> [ClaimMilestone] {
        var out: [ClaimMilestone] = []
        for item in items {
            let derived = newClaimMilestone(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateClaimMilestone(_ item: ClaimMilestone) -> String {
        return classifyDenialAudit(item.adjustedLoad())
    }
}
