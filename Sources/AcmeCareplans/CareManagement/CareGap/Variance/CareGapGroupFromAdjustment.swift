import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingCareGapAdjustmentsForGroup(_ items: [RollingCareGapAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveCareGapGroupsFromAdjustment(_ items: [RollingCareGapAdjustment]) -> [CareGapGroup] {
        var out: [CareGapGroup] = []
        for item in items {
            let derived = newCareGapGroup(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreCareGapGroup(_ item: CareGapGroup) -> String {
        return normalizePendingCareGapNoticeCode(item.code)
    }
}
