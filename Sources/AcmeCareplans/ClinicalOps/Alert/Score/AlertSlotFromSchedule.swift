import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolSchedulesForSlot(_ items: [CareProtocolSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveAlertSlotsFromSchedule(_ items: [CareProtocolSchedule]) -> [AlertSlot] {
        var out: [AlertSlot] = []
        for item in items {
            let derived = newAlertSlot(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAlertSlot(_ item: AlertSlot) -> String {
        return careProtocolScheduleBucket(item.weightedValue())
    }
}
