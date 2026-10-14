import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeModalityEntriesForSchedule(_ items: [ModalityEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveCareProtocolSchedulesFromEntry(_ items: [ModalityEntry]) -> [CareProtocolSchedule] {
        var out: [CareProtocolSchedule] = []
        for item in items {
            let derived = newCareProtocolSchedule(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitCareProtocolSchedule(_ item: CareProtocolSchedule) -> Double {
        return modalityEntryWeight(2, active: true)
    }
}
