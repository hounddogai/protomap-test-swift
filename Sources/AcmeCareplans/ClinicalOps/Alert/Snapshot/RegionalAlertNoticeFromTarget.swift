import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingHandoffTargetsForNotice(_ items: [PendingHandoffTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveRegionalAlertNoticesFromTarget(_ items: [PendingHandoffTarget]) -> [RegionalAlertNotice] {
        var out: [RegionalAlertNotice] = []
        for item in items {
            let derived = newRegionalAlertNotice(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeRegionalAlertNotice(_ item: RegionalAlertNotice) -> String {
        return normalizeManualHandoffScheduleCode(item.code)
    }
}
