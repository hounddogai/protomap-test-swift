import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultSpecimenQuotasForSchedule(_ items: [DefaultSpecimenQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRegionalResultSchedulesFromQuota(_ items: [DefaultSpecimenQuota]) -> [RegionalResultSchedule] {
        var out: [RegionalResultSchedule] = []
        for item in items {
            let derived = newRegionalResultSchedule(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planRegionalResultSchedule(_ item: RegionalResultSchedule) -> String {
        return normalizeSpecimenWindowCode(item.code)
    }
}
