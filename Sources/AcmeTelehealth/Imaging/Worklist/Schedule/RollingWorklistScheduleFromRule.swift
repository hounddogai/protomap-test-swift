import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeRegionalCareProtocolRulesForSchedule(_ items: [RegionalCareProtocolRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRollingWorklistSchedulesFromRule(_ items: [RegionalCareProtocolRule]) -> [RollingWorklistSchedule] {
        var out: [RollingWorklistSchedule] = []
        for item in items {
            let derived = newRollingWorklistSchedule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateRollingWorklistSchedule(_ item: RollingWorklistSchedule) -> Double {
        return careProtocolManifestWeight(9, active: true)
    }
}
