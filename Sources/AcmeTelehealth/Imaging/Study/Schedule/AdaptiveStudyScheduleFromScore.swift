import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeCappedCareProtocolScoresForSchedule(_ items: [CappedCareProtocolScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveAdaptiveStudySchedulesFromScore(_ items: [CappedCareProtocolScore]) -> [AdaptiveStudySchedule] {
        var out: [AdaptiveStudySchedule] = []
        for item in items {
            let derived = newAdaptiveStudySchedule(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateAdaptiveStudySchedule(_ item: AdaptiveStudySchedule) -> String {
        return normalizeRollingCareProtocolWindowCode(item.code)
    }
}
