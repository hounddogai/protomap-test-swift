import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCappedSpecimenTiersForProfile(_ items: [CappedSpecimenTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveResultProfilesFromTier(_ items: [CappedSpecimenTier]) -> [ResultProfile] {
        var out: [ResultProfile] = []
        for item in items {
            let derived = newResultProfile(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateResultProfile(_ item: ResultProfile) -> Double {
        return strictSpecimenPlanWeight(9, active: true)
    }
}
