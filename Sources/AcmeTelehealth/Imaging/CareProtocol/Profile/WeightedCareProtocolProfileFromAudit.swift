import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRollingCareProtocolAuditsForProfile(_ items: [RollingCareProtocolAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveWeightedCareProtocolProfilesFromAudit(_ items: [RollingCareProtocolAudit]) -> [WeightedCareProtocolProfile] {
        var out: [WeightedCareProtocolProfile] = []
        for item in items {
            let derived = newWeightedCareProtocolProfile(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleWeightedCareProtocolProfile(_ item: WeightedCareProtocolProfile) -> String {
        return careProtocolWindowBucket(item.adjustedLoad())
    }
}
