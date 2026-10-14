import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolMilestonesForQuota(_ items: [FloatPoolMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func derivePrimaryFloatPoolQuotasFromMilestone(_ items: [FloatPoolMilestone]) -> [PrimaryFloatPoolQuota] {
        var out: [PrimaryFloatPoolQuota] = []
        for item in items {
            let derived = newPrimaryFloatPoolQuota(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankPrimaryFloatPoolQuota(_ item: PrimaryFloatPoolQuota) -> String {
        return weightedFloatPoolTargetBucket(item.projectedLoad())
    }
}
