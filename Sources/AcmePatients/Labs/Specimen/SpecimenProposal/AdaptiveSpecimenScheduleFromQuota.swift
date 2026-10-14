import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAccessionQuotasForSchedule(_ items: [AccessionQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveAdaptiveSpecimenSchedulesFromQuota(_ items: [AccessionQuota]) -> [AdaptiveSpecimenSchedule] {
        var out: [AdaptiveSpecimenSchedule] = []
        for item in items {
            let derived = newAdaptiveSpecimenSchedule(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyAdaptiveSpecimenSchedule(_ item: AdaptiveSpecimenSchedule) -> String {
        return classifyRollingAccessionScore(item.effectiveValue())
    }
}
