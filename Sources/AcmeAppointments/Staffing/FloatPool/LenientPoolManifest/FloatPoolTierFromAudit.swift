import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledFloatPoolAuditsForTier(_ items: [ScheduledFloatPoolAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveFloatPoolTiersFromAudit(_ items: [ScheduledFloatPoolAudit]) -> [FloatPoolTier] {
        var out: [FloatPoolTier] = []
        for item in items {
            let derived = newFloatPoolTier(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeFloatPoolTier(_ item: FloatPoolTier) -> String {
        return scheduledFloatPoolAuditBucket(item.netExposure())
    }
}
