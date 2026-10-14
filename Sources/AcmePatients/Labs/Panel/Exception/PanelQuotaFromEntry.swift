import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualCourierEntriesForQuota(_ items: [ManualCourierEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePanelQuotasFromEntry(_ items: [ManualCourierEntry]) -> [PanelQuota] {
        var out: [PanelQuota] = []
        for item in items {
            let derived = newPanelQuota(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePanelQuota(_ item: PanelQuota) -> String {
        return normalizeCourierDraftCode(item.code)
    }
}
