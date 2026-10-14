import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryPanelEstimatesForSchedule(_ items: [PrimaryPanelEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveRegionalResultSchedulesFromEstimate(_ items: [PrimaryPanelEstimate]) -> [RegionalResultSchedule] {
        var out: [RegionalResultSchedule] = []
        for item in items {
            let derived = newRegionalResultSchedule(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateRegionalResultSchedule(_ item: RegionalResultSchedule) -> String {
        return normalizePrimaryPanelEstimateCode(item.code)
    }
}
