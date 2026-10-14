import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeScheduledModalityAuditsForPolicy(_ items: [ScheduledModalityAudit]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveSeasonalCareProtocolPoliciesFromAudit(_ items: [ScheduledModalityAudit]) -> [SeasonalCareProtocolPolicy] {
        var out: [SeasonalCareProtocolPolicy] = []
        for item in items {
            let derived = newSeasonalCareProtocolPolicy(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignSeasonalCareProtocolPolicy(_ item: SeasonalCareProtocolPolicy) -> String {
        return classifyScheduledModalityAudit(item.measuredValue())
    }
}
