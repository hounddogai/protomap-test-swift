import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeOvertimeLedgersForSlot(_ items: [OvertimeLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOvertimeSlotsFromLedger(_ items: [OvertimeLedger]) -> [OvertimeSlot] {
        var out: [OvertimeSlot] = []
        for item in items {
            let derived = newOvertimeSlot(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveOvertimeSlot(_ item: OvertimeSlot) -> Double {
        return rollingOvertimeScoreWeight(3, active: true)
    }
}
