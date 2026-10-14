import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularySchedulesForSlot(_ items: [FormularySchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDispenseSlotsFromSchedule(_ items: [FormularySchedule]) -> [DispenseSlot] {
        var out: [DispenseSlot] = []
        for item in items {
            let derived = newDispenseSlot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyDispenseSlot(_ item: DispenseSlot) -> Double {
        return formularyScheduleWeight(7, active: true)
    }
}
