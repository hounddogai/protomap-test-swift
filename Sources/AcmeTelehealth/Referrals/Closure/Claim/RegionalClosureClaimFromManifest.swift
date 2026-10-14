import AcmePlatform
import Foundation

extension Referrals {
    static func summarizePrimarySlotManifestsForClaim(_ items: [PrimarySlotManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRegionalClosureClaimsFromManifest(_ items: [PrimarySlotManifest]) -> [RegionalClosureClaim] {
        var out: [RegionalClosureClaim] = []
        for item in items {
            let derived = newRegionalClosureClaim(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalClosureClaim(_ item: RegionalClosureClaim) -> String {
        return strictSlotAssignmentBucket(item.adjustedLoad())
    }
}
