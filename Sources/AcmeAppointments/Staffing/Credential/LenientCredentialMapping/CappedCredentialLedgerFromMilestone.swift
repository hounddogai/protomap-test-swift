import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeTieredSkillMixMilestonesForLedger(_ items: [TieredSkillMixMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedCredentialLedgersFromMilestone(_ items: [TieredSkillMixMilestone]) -> [CappedCredentialLedger] {
        var out: [CappedCredentialLedger] = []
        for item in items {
            let derived = newCappedCredentialLedger(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeCappedCredentialLedger(_ item: CappedCredentialLedger) -> Double {
        return skillMixRecordWeight(7, active: true)
    }
}
